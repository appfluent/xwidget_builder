# XWidget schema tests

Programmatic tests for the XWidget XSD using `xmllint`.

## Quick start

From your XWidget project root, after generating the schema:

```bash
cd schema_tests
./run_tests.sh                          # uses ../fixtures/.xwidget/fragments_schema.g.xsd
./run_tests.sh /path/to/fragments_schema.g.xsd  # explicit path
```

Expected output:

```
Validating schema syntax...
✓ Schema XML well-formed

=== Positive tests (should validate) ===
  ✓ test_basic_widget.xml
  ✓ test_builtin_inflaters.xml
  ✓ test_builtin_tags.xml
  ...

=== Negative tests (should fail validation) ===
  ✓ bad_else_outside_if.xml (correctly rejected)
  ✓ bad_entry_outside_map.xml (correctly rejected)
  ...

==========================
Results: 14 passed, 0 failed
==========================
```

## Requirements

`xmllint` (part of libxml2):

- macOS: pre-installed
- Ubuntu/Debian: `sudo apt install libxml2-utils`
- Other Linux: package usually called `libxml2` or `libxml2-utils`

## File naming convention

| Prefix | Expected behavior |
|---|---|
| `test_*.xml` | Should validate clean. Failure = a regression in the schema. |
| `bad_*.xml` | Should fail validation. Failure to fail = a missed restriction in the schema. |

## What's covered

### Positive tests

| File | Exercises |
|---|---|
| `test_basic_widget.xml` | Vanilla widget composition, Text content |
| `test_builtin_tags.xml` | All 8 lowercase structural tags (`builder`, `callback`, `debug`, `forEach`, `forLoop`, `fragment`, `if`, `var`) |
| `test_builtin_inflaters.xml` | All 7 capitalized inflater tags (`Controller`, `DynamicBuilder`, `EventListener`, `List`, `Map`, `MediaQuery`, `ValueListener`) |
| `test_param_in_forloop.xml` | `<param>` allowed inside `<forLoop>` (added with the components-group rework) |
| `test_param_in_foreach.xml` | `<param>` allowed inside `<forEach>` |
| `test_else_in_if.xml` | `<else>` inside `<if>`, `<param>` inside both |
| `test_mixed_content.xml` | Text content inside a widget (the `Text` use case for `mixed="true"`) |
| `test_list_with_items.xml` | `<List>` with `<Item>` children — exercises the `mixed="true"` fix on List's complexContent |
| `test_map_with_entries.xml` | `<Map>` with `<Entry>` children |

### Negative tests (should be rejected)

| File | What it tries to do that the schema should forbid |
|---|---|
| `bad_unknown_widget.xml` | Use a tag (`<NotAWidget/>`) that's not in `allComponents` |
| `bad_else_outside_if.xml` | Use `<else>` directly under a widget (only valid inside `<if>`) |
| `bad_param_in_widget.xml` | Use `<param>` inside a widget (only valid in fragment/if/else/forEach/forLoop) |
| `bad_entry_outside_map.xml` | Use `<Entry>` outside `<Map>` |
| `bad_item_outside_list.xml` | Use `<Item>` outside `<List>` |

## What's NOT covered

These tests focus on the structural changes from the components-group work.
They do NOT exhaustively test:

- Every individual generated inflater (Column, Container, etc. — too many)
- Attribute-level validation (enum types, `boolAttributeType`, etc.)
- Complex EL expression validation
- IDE-specific behaviors (completion popups, hover rendering)

For attribute-level coverage, add fixtures using the same naming convention.

## Adding new tests

1. Create `test_*.xml` (positive) or `bad_*.xml` (negative) in this directory
2. Re-run `./run_tests.sh`

The runner picks up any file matching the prefix conventions automatically.

## Caveats

- Tests assume fragments declare the XWidget namespace as default:
  `xmlns="https://xwidget.dev/fragments"`. Adjust if your fragment
  conventions differ.
- The runner exits 1 on any test failure, so it's CI-friendly.
- `xmllint` schema validation is XSD 1.0 — if the schema uses XSD 1.1
  features, results may differ from validators like Xerces or Saxon.
