from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest


SCRIPT = Path(sys.argv.pop(1)).resolve()


class WinRunTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home"
        self.workspace = self.root / "workspace"
        self.legacy = self.root / "legacy"
        self.proton = self.root / "proton"
        self.proton.mkdir()
        self.capture = self.root / "capture.jsonl"
        self.umu = self.root / "umu-run"
        self.write_executable(
            self.umu,
            f"#!{sys.executable}\n"
            + textwrap.dedent(
                """
                import json, os, sys
                keys = ["GAMEID", "STORE", "WINEPREFIX", "PROTONPATH", "PROTON_VERB",
                        "UMU_CONTAINER_NSENTER", "UMU_USE_STEAM", "MANGOHUD_CONFIG"]
                with open(os.environ["FAKE_CAPTURE"], "a", encoding="utf-8") as file:
                    file.write(json.dumps({"argv": sys.argv[1:],
                        "env": {key: os.environ.get(key) for key in keys}}, ensure_ascii=False) + "\\n")
                raise SystemExit(int(os.environ.get("FAKE_EXIT", "0")))
                """
            ),
        )
        self.environment = os.environ.copy()
        self.environment.update(
            {
                "HOME": str(self.home),
                "WIN_RUN_WORKSPACE": str(self.workspace),
                "WIN_RUN_LEGACY_WORKSPACE": str(self.legacy),
                "WIN_RUN_PROTON": str(self.proton),
                "WIN_RUN_UMU": str(self.umu),
                "WIN_RUN_STARTUP_TIMEOUT": "0",
                "FAKE_CAPTURE": str(self.capture),
                "LANG": "ko_KR.UTF-8",
            }
        )

    def write_executable(self, path: Path, source: str) -> None:
        path.write_text(textwrap.dedent(source).lstrip(), encoding="utf-8")
        path.chmod(0o755)

    def invoke(self, *arguments: str, **environment: str) -> subprocess.CompletedProcess[str]:
        env = self.environment | environment
        return subprocess.run(
            [sys.executable, str(SCRIPT), *arguments],
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def captured(self) -> list[dict[str, object]]:
        if not self.capture.exists():
            return []
        return [json.loads(line) for line in self.capture.read_text(encoding="utf-8").splitlines()]

    def shortcut_dir(self, root: Path | None = None) -> Path:
        path = (root or self.workspace) / "drive_c" / "proton_shortcuts"
        path.mkdir(parents=True, exist_ok=True)
        return path

    def desktop(
        self,
        filename: str,
        *,
        name: str,
        shortcut: str,
        icon: str = "",
        extra: str = "",
        root: Path | None = None,
    ) -> Path:
        path = self.shortcut_dir(root) / filename
        escaped = shortcut.replace("\\", "\\\\")
        path.write_text(
            textwrap.dedent(
                f"""
                [Desktop Entry]
                Type=Application
                Name={name}
                Name[ko]={name} (한국어)
                Comment=Windows application
                Exec="{escaped}"
                Icon={icon}
                {extra}
                """
            ).strip()
            + "\n",
            encoding="utf-8",
        )
        return path

    def test_list_is_empty_before_workspace_initialization(self) -> None:
        result = self.invoke("list")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(json.loads(result.stdout), [])
        self.assertEqual(result.stderr, "")

    def test_list_projects_shortcuts_filters_and_selects_largest_icon(self) -> None:
        shortcut = r"C:\users\Public\Desktop\앱 이름.lnk"
        self.desktop("app.desktop", name="앱 이름", shortcut=shortcut, icon="CAFE_app.0")
        self.desktop("duplicate.desktop", name="Renamed duplicate", shortcut=shortcut)
        self.desktop("uninstall.desktop", name="Uninstall 앱", shortcut=r"C:\uninstall.lnk")
        self.desktop("hidden.desktop", name="Hidden", shortcut=r"C:\hidden.lnk", extra="NoDisplay=true")
        icons = self.shortcut_dir() / "icons"
        for size in ("32x32", "256x256"):
            path = icons / size / "apps" / "CAFE_app.0.png"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"png")

        result = self.invoke("list")
        catalog = json.loads(result.stdout)
        self.assertEqual(len(catalog), 1)
        self.assertEqual(catalog[0]["name"], "win-run: 앱 이름 (한국어)")
        self.assertEqual(catalog[0]["description"], "Windows application")
        self.assertIn("/256x256/", catalog[0]["icon"])
        self.assertRegex(catalog[0]["exec"], r"^win-run launch wr1-[0-9a-f]{24}$")

    def test_entry_id_does_not_depend_on_display_name(self) -> None:
        desktop = self.desktop("app.desktop", name="Before", shortcut=r"C:\App\app.lnk")
        before = json.loads(self.invoke("list").stdout)[0]["exec"]
        desktop.write_text(desktop.read_text(encoding="utf-8").replace("Before", "After"), encoding="utf-8")
        after = json.loads(self.invoke("list").stdout)[0]["exec"]
        self.assertEqual(before, after)

    def test_malformed_desktop_diagnostic_does_not_corrupt_json(self) -> None:
        path = self.shortcut_dir() / "bad.desktop"
        path.write_text("[Desktop Entry]\nName=Bad\nExec=sh -c boom\n", encoding="utf-8")
        result = self.invoke("list")
        self.assertEqual(json.loads(result.stdout), [])
        self.assertIn("ignoring bad.desktop", result.stderr)

    def test_launch_resolves_id_and_sets_minimal_workspace_environment(self) -> None:
        shortcut = r"C:\Program Files\한글 앱\app.lnk"
        self.desktop("app.desktop", name="App", shortcut=shortcut)
        entry = json.loads(self.invoke("list").stdout)[0]
        entry_id = entry["exec"].split()[-1]

        result = self.invoke("launch", entry_id, UMU_USE_STEAM="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        invocation = self.captured()[0]
        self.assertEqual(invocation["argv"], [shortcut])
        self.assertEqual(invocation["env"]["GAMEID"], "win-run-default")
        self.assertEqual(invocation["env"]["WINEPREFIX"], str(self.workspace))
        self.assertEqual(invocation["env"]["PROTON_VERB"], "run")
        self.assertEqual(invocation["env"]["UMU_CONTAINER_NSENTER"], "1")
        self.assertIsNone(invocation["env"]["UMU_USE_STEAM"])
        self.assertIsNone(invocation["env"]["MANGOHUD_CONFIG"])

    def test_open_preserves_unicode_spaces_quotes_and_exit_status(self) -> None:
        target = self.root / "설치 파일.exe"
        target.write_bytes(b"MZ")
        arguments = ["space value", 'a"quote', "한글"]
        result = self.invoke("open", str(target), "--", *arguments, FAKE_EXIT="17")
        self.assertEqual(result.returncode, 17)
        self.assertEqual(self.captured()[0]["argv"], [str(target), *arguments])

    def test_open_accepts_msi_and_rejects_unsupported_or_missing_files(self) -> None:
        msi = self.root / "installer.MSI"
        msi.write_bytes(b"msi")
        self.assertEqual(self.invoke("open", str(msi)).returncode, 0)
        unsupported = self.root / "script.bat"
        unsupported.write_text("exit", encoding="utf-8")
        self.assertEqual(self.invoke("open", str(unsupported)).returncode, 2)
        self.assertEqual(self.invoke("open", str(self.root / "missing.exe")).returncode, 2)

    def test_launch_rejects_malformed_and_unknown_ids(self) -> None:
        self.assertEqual(self.invoke("launch", "$(touch nope)").returncode, 2)
        self.assertEqual(self.invoke("launch", "wr1-" + "0" * 24).returncode, 2)
        self.assertEqual(self.captured(), [])

    def test_migration_moves_updates_validates_and_is_idempotent(self) -> None:
        self.desktop("app.desktop", name="App", shortcut=r"C:\App.lnk", root=self.legacy)
        first = self.invoke("migrate")
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertFalse(self.legacy.exists())
        self.assertTrue(self.workspace.exists())
        self.assertEqual(self.captured()[0]["argv"], ["createprefix"])
        self.assertEqual(len(json.loads(self.invoke("list").stdout)), 1)
        second = self.invoke("migrate")
        self.assertEqual(second.returncode, 0)
        self.assertEqual(len(self.captured()), 1)

    def test_migration_refuses_conflict_and_active_service(self) -> None:
        self.legacy.mkdir()
        self.workspace.mkdir()
        self.assertEqual(self.invoke("migrate").returncode, 2)
        self.workspace.rmdir()

        digest = hashlib.md5(str(self.legacy).encode(), usedforsecurity=False).hexdigest()
        client = self.root / "launch-client"
        self.write_executable(
            client,
            f"#!{sys.executable}\nprint('--bus-name=com.steampowered.App{digest}')\n",
        )
        result = self.invoke("migrate", WIN_RUN_LAUNCH_CLIENT=str(client))
        self.assertEqual(result.returncode, 2)
        self.assertTrue(self.legacy.exists())

    def test_failed_migration_restores_source(self) -> None:
        self.legacy.mkdir()
        result = self.invoke("migrate", FAKE_EXIT="9")
        self.assertEqual(result.returncode, 2)
        self.assertTrue(self.legacy.exists())
        self.assertFalse(self.workspace.exists())


if __name__ == "__main__":
    unittest.main()
