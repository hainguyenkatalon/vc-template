# SPEC context generation

Use this when `SPEC_CONTEXT.md` is missing or out of date.

1. From the repo root, run:
   ```bash
   specs/tools/gen-spec-context.sh
   ```
2. The script detects the current Git branch, maps it to `specs/<branch>/`, and writes `SPEC_CONTEXT.md` using the template placeholders.
3. If your spec folder differs from `specs/<branch>/`, override it with:
   ```bash
   SPEC_DIR_OVERRIDE="specs/custom-folder" specs/tools/gen-spec-context.sh
   ```
4. Commit the template if paths change. The generated `SPEC_CONTEXT.md` remains gitignored.
