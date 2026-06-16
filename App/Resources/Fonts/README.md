# Fonts

Place the **Vazirmatn** TrueType files here for polished Persian typography:

- `Vazirmatn-Regular.ttf`
- `Vazirmatn-Bold.ttf`

They are intentionally **not committed** (see `.gitignore`). Fetch them with:

```bash
./scripts/fetch-fonts.sh
```

The app registers any `.ttf` in its bundle at runtime (`FontRegistrar`). If the
fonts are absent, the UI falls back gracefully to the system font — the app
still builds and runs. Vazirmatn is licensed under the SIL Open Font License.
