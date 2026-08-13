"""Bind Git metadata paths without following links or repository overrides."""

from dataclasses import dataclass
import hashlib
import os
from pathlib import Path, PurePosixPath
import stat


MAX_GIT_POINTER_BYTES = 4096
MAX_GIT_INDEX_BYTES = 128 * 1024 * 1024
MAX_LOOSE_TAG_REF_BYTES = 4096
MAX_PACKED_REFS_BYTES = 64 * 1024 * 1024
CONTENT_HASH_CHUNK_BYTES = 1024 * 1024


class GitMetadataError(ValueError):
    """One non-reflective Git metadata path failure."""


@dataclass(frozen=True)
class GitMetadataBinding:
    """A repeatable metadata snapshot that can be checked after Git reads."""

    kind: str
    repository_root: Path
    tag_name: str | None
    state: tuple


def bind_index(repository_root):
    """Bind the actual normal or linked-worktree index as a regular leaf."""
    root = _absolute_path(repository_root)
    git_directory, _common_directory, layout = _discover_layout(root)
    state = (
        layout,
        _snapshot_relative(
            git_directory,
            ("index",),
            "regular",
            True,
            maximum_bytes=MAX_GIT_INDEX_BYTES,
        ),
    )
    return GitMetadataBinding("index", root, None, state)


def bind_tag_refs(repository_root, tag_name):
    """Bind only one exact loose tag path and the optional packed-refs leaf."""
    root = _absolute_path(repository_root)
    tag_parts = _tag_path_parts(tag_name)
    _git_directory, common_directory, layout = _discover_layout(root)
    state = (
        layout,
        _snapshot_relative(
            common_directory,
            ("refs", "tags", *tag_parts),
            "regular",
            False,
            maximum_bytes=MAX_LOOSE_TAG_REF_BYTES,
        ),
        _snapshot_relative(
            common_directory,
            ("packed-refs",),
            "regular",
            False,
            maximum_bytes=MAX_PACKED_REFS_BYTES,
        ),
    )
    return GitMetadataBinding("tag", root, tag_name, state)


def verify_binding(binding):
    """Require the bound layout and metadata identities to remain unchanged."""
    if not isinstance(binding, GitMetadataBinding):
        raise GitMetadataError("Git metadata is unsafe")
    if binding.kind == "index":
        current = bind_index(binding.repository_root)
    elif binding.kind == "tag" and binding.tag_name is not None:
        current = bind_tag_refs(binding.repository_root, binding.tag_name)
    else:
        raise GitMetadataError("Git metadata is unsafe")
    if current.state != binding.state:
        raise GitMetadataError("Git metadata changed during read")


def _absolute_path(value):
    try:
        return Path(os.path.abspath(os.fspath(value)))
    except (OSError, TypeError, ValueError) as error:
        raise GitMetadataError("Git metadata is unsafe") from error


def _is_reparse(status):
    return bool(
        getattr(status, "st_file_attributes", 0)
        & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
    )


def _component_identity(status):
    return (
        getattr(status, "st_dev", None),
        getattr(status, "st_ino", None),
        stat.S_IFMT(status.st_mode),
        _is_reparse(status),
    )


def _leaf_identity(status):
    return (
        *_component_identity(status),
        getattr(status, "st_size", None),
        getattr(status, "st_mtime_ns", None),
    )


def _absolute_components(path):
    parts = Path(path).parts
    if not parts:
        raise GitMetadataError("Git metadata is unsafe")
    current = Path(parts[0])
    components = [current]
    for part in parts[1:]:
        current = current / part
        components.append(current)
    return tuple(components)


def _snapshot_directory_path(path):
    identities = []
    for component in _absolute_components(path):
        try:
            status = component.lstat()
        except OSError as error:
            raise GitMetadataError("Git metadata is unsafe") from error
        if (
            not stat.S_ISDIR(status.st_mode)
            or stat.S_ISLNK(status.st_mode)
            or _is_reparse(status)
        ):
            raise GitMetadataError("Git metadata is unsafe")
        identities.append(_component_identity(status))
    return tuple(identities)


def _snapshot_relative(
    base, parts, leaf_kind, required, *, maximum_bytes=None
):
    if not parts or leaf_kind not in {"directory", "regular"}:
        raise GitMetadataError("Git metadata is unsafe")
    if maximum_bytes is not None and (
        leaf_kind != "regular"
        or type(maximum_bytes) is not int
        or maximum_bytes < 0
    ):
        raise GitMetadataError("Git metadata is unsafe")
    base_path = Path(base)
    identities = list(_snapshot_directory_path(base_path))
    current = base_path
    for index, part in enumerate(parts):
        if type(part) is not str or not part or part in {".", ".."}:
            raise GitMetadataError("Git metadata is unsafe")
        current = current / part
        is_leaf = index == len(parts) - 1
        try:
            status = current.lstat()
        except FileNotFoundError as error:
            if required:
                raise GitMetadataError("Git metadata is unsafe") from error
            return ("missing", index, tuple(identities))
        except OSError as error:
            raise GitMetadataError("Git metadata is unsafe") from error
        if stat.S_ISLNK(status.st_mode) or _is_reparse(status):
            raise GitMetadataError("Git metadata is unsafe")
        expected_directory = not is_leaf or leaf_kind == "directory"
        if expected_directory:
            if not stat.S_ISDIR(status.st_mode):
                raise GitMetadataError("Git metadata is unsafe")
            identities.append(_component_identity(status))
        else:
            if not stat.S_ISREG(status.st_mode):
                raise GitMetadataError("Git metadata is unsafe")
            identities.append(_leaf_identity(status))
    snapshot = ("present", tuple(identities))
    if leaf_kind == "regular" and maximum_bytes is not None:
        snapshot += (
            _digest_regular_leaf(current, identities[-1], maximum_bytes),
        )
    return snapshot


def _digest_regular_leaf(path, expected_identity, maximum_bytes):
    """Hash one bounded regular leaf without following its final component."""
    flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
    descriptor = None
    try:
        descriptor = os.open(path, flags)
        with os.fdopen(descriptor, "rb") as stream:
            descriptor = None
            opened = os.fstat(stream.fileno())
            if (
                not stat.S_ISREG(opened.st_mode)
                or _is_reparse(opened)
                or _leaf_identity(opened) != expected_identity
            ):
                raise GitMetadataError("Git metadata is unsafe")
            digest = hashlib.sha256()
            total = 0
            while True:
                chunk = stream.read(CONTENT_HASH_CHUNK_BYTES)
                if not chunk:
                    break
                total += len(chunk)
                if total > maximum_bytes:
                    raise GitMetadataError("Git metadata is unsafe")
                digest.update(chunk)
            opened_after = os.fstat(stream.fileno())
    except GitMetadataError:
        raise
    except OSError as error:
        raise GitMetadataError("Git metadata is unsafe") from error
    finally:
        if descriptor is not None:
            os.close(descriptor)
    try:
        final = Path(path).lstat()
    except OSError as error:
        raise GitMetadataError("Git metadata is unsafe") from error
    if (
        _leaf_identity(opened_after) != expected_identity
        or _leaf_identity(final) != expected_identity
    ):
        raise GitMetadataError("Git metadata is unsafe")
    return digest.digest()


def _read_pointer_file(base, parts):
    initial = _snapshot_relative(base, parts, "regular", True)
    path = Path(base).joinpath(*parts)
    flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
    descriptor = None
    try:
        descriptor = os.open(path, flags)
        with os.fdopen(descriptor, "rb") as stream:
            descriptor = None
            opened = os.fstat(stream.fileno())
            if not stat.S_ISREG(opened.st_mode) or _is_reparse(opened):
                raise GitMetadataError("Git metadata is unsafe")
            raw = stream.read(MAX_GIT_POINTER_BYTES + 1)
            opened_after = os.fstat(stream.fileno())
    except GitMetadataError:
        raise
    except OSError as error:
        raise GitMetadataError("Git metadata is unsafe") from error
    finally:
        if descriptor is not None:
            os.close(descriptor)
    final = _snapshot_relative(base, parts, "regular", True)
    if (
        len(raw) > MAX_GIT_POINTER_BYTES
        or initial != final
        or initial[1][-1] != _leaf_identity(opened)
        or initial[1][-1] != _leaf_identity(opened_after)
    ):
        raise GitMetadataError("Git metadata is unsafe")
    return raw, initial


def _decode_pointer(raw, prefix, base):
    line = raw.rstrip(b"\r\n")
    if raw not in (line, line + b"\n", line + b"\r\n") or not line.startswith(prefix):
        raise GitMetadataError("Git metadata is unsafe")
    try:
        value = line[len(prefix) :].decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise GitMetadataError("Git metadata is unsafe") from error
    if not value or "\0" in value:
        raise GitMetadataError("Git metadata is unsafe")
    candidate = Path(value)
    if not candidate.is_absolute():
        candidate = Path(base) / candidate
    candidate = _absolute_path(candidate)
    _snapshot_directory_path(candidate)
    return candidate


def _discover_layout(repository_root):
    root = _absolute_path(repository_root)
    root_state = _snapshot_directory_path(root)
    dot_git = root / ".git"
    try:
        dot_git_status = dot_git.lstat()
    except OSError as error:
        raise GitMetadataError("Git metadata is unsafe") from error
    if (
        stat.S_ISDIR(dot_git_status.st_mode)
        and not stat.S_ISLNK(dot_git_status.st_mode)
        and not _is_reparse(dot_git_status)
    ):
        git_directory = dot_git
        dot_git_state = _snapshot_relative(root, (".git",), "directory", True)
    elif (
        stat.S_ISREG(dot_git_status.st_mode)
        and not stat.S_ISLNK(dot_git_status.st_mode)
        and not _is_reparse(dot_git_status)
    ):
        raw, dot_git_state = _read_pointer_file(root, (".git",))
        git_directory = _decode_pointer(raw, b"gitdir: ", root)
    else:
        raise GitMetadataError("Git metadata is unsafe")
    git_directory_state = _snapshot_directory_path(git_directory)

    common_pointer = git_directory / "commondir"
    try:
        common_status = common_pointer.lstat()
    except FileNotFoundError:
        common_directory = git_directory
        common_pointer_state = _snapshot_relative(
            git_directory, ("commondir",), "regular", False
        )
    except OSError as error:
        raise GitMetadataError("Git metadata is unsafe") from error
    else:
        if (
            not stat.S_ISREG(common_status.st_mode)
            or stat.S_ISLNK(common_status.st_mode)
            or _is_reparse(common_status)
        ):
            raise GitMetadataError("Git metadata is unsafe")
        raw, common_pointer_state = _read_pointer_file(
            git_directory, ("commondir",)
        )
        common_directory = _decode_pointer(raw, b"", git_directory)
    common_directory_state = _snapshot_directory_path(common_directory)
    layout = (
        root_state,
        dot_git_state,
        git_directory_state,
        common_pointer_state,
        common_directory_state,
        os.path.normcase(os.fspath(git_directory)),
        os.path.normcase(os.fspath(common_directory)),
    )
    return git_directory, common_directory, layout


def _tag_path_parts(tag_name):
    try:
        encoded_length = len(tag_name.encode("utf-8", errors="strict"))
    except (AttributeError, UnicodeEncodeError) as error:
        raise GitMetadataError("Git metadata is unsafe") from error
    if (
        type(tag_name) is not str
        or not tag_name
        or encoded_length > 1024
        or "\0" in tag_name
        or "\\" in tag_name
    ):
        raise GitMetadataError("Git metadata is unsafe")
    path = PurePosixPath(tag_name)
    if (
        path.is_absolute()
        or not path.parts
        or any(part in {"", ".", ".."} for part in path.parts)
        or str(path) != tag_name
    ):
        raise GitMetadataError("Git metadata is unsafe")
    return tuple(path.parts)
