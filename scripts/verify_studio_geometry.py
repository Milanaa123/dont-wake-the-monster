#!/usr/bin/env python3
"""Verify real Roblox Studio mesh files after the Codex art bake.

No Roblox render or gameplay simulation: checks binary integrity, wasted
vertices, usable normals, UV range, sound headers and generated place.
"""
from pathlib import Path
import math
import struct
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("dist/StudioKit")
assert root.is_dir(), f"Studio kit is missing: {root}"
mesh_files = sorted(root.rglob("*.mesh"))
assert len(mesh_files) >= 300, f"Expected >=300 authored 3D sections, got {len(mesh_files)}"

total_vertices = 0
total_faces = 0
for file in mesh_files:
    data = file.read_bytes()
    assert data.startswith(b"version 2.00\n"), f"Invalid Roblox mesh signature: {file}"
    assert len(data) >= 25, f"Truncated Roblox mesh: {file}"
    header_size, vertex_size, face_size, count, triangles = struct.unpack_from("<HBBII", data, 13)
    assert (header_size, vertex_size, face_size) == (12, 36, 12), (
        f"Unsupported mesh format: {file} ({header_size}, {vertex_size}, {face_size})"
    )
    assert count > 0 and triangles > 0, f"Empty geometry: {file}"
    assert len(data) == 25 + count * 36 + triangles * 12, f"Truncated mesh payload: {file}"
    for i in range(count):
        v = struct.unpack_from("<8f4b", data, 25 + 36 * i)
        assert all(math.isfinite(x) for x in v[:8]), f"Non-finite vertex: {file}, {i}"
        assert sum(x*x for x in v[3:6]) > 0.1, f"Invalid normal: {file}, {i}"
        assert all(-0.01 <= coord <= 1.01 for coord in v[6:8]), f"Invalid UV: {file}, {i}"
    face_start = 25 + count * 36
    referenced = set()
    for i in range(triangles):
        a,b,c = struct.unpack_from("<3I", data, face_start + i * 12)
        assert len({a,b,c}) == 3 and max(a,b,c) < count, (
            f"Invalid triangle: {file}, {i}"
        )
        referenced.update((a,b,c))
    assert len(referenced) == count, (
        f"{count - len(referenced)} orphan vertices in {file}"
    )
    total_vertices += count
    total_faces += triangles

wav_files = list(root.rglob("*.wav"))
assert len(wav_files) >= 19, f"Missing original audio: {len(wav_files)} WAVs"
for file in wav_files:
    data = file.read_bytes()[:12]
    assert data[:4] == b"RIFF" and data[8:] == b"WAVE", f"Invalid WAV header: {file}"
assert any(file.name == "pigments.png" for file in root.rglob("*.png")), (
    "Packed painterly pigment atlas missing"
)
assert (root / "DontWakeTheMonster-Studio.rbxlx").is_file(), (
    "Built native Roblox Studio place missing"
)
print(
    f"PASS: {len(mesh_files)} mesh sections, {total_vertices:,} referenced "
    f"vertices, {total_faces:,} triangles, {len(wav_files)} original WAVs; "
    "no orphan vertices, invalid normals or corrupt indices"
)
