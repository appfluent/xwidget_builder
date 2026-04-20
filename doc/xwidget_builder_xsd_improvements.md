# xwidget_builder — XSD generation improvements

Two fixes to the generated `xwidget_schema.g.xsd` that meaningfully improve the
editor experience for any XML tooling that uses it (Red Hat XML / LemMinX in
VSCode, Eclipse, IntelliJ generic XML support, online XSD validators, etc.).

Both were discovered while building the Flutter XWidget VSCode extension. Both
were tested by hand-editing the generated XSD and confirming the editor
behavior changed. Both are XSD-side fixes — no changes needed in the runtime,
the inflater code, or anything that consumes the schema. They only affect how
authoring tools read the schema.

## Fix 1 — Replace `xs:any` wildcards with a shared `xs:group` choice

### Current behavior

Every type that allows widget children uses an `xs:any` wildcard:

```xml
<xs:complexType name="objectType" mixed="true">
    <xs:sequence>
        <xs:any namespace="##targetNamespace"
                minOccurs="0" maxOccurs="unbounded"/>
    </xs:sequence>
    ...
</xs:complexType>
```

Same pattern in `listItemType`, `mapEntryType`, `paramType`, and inside the
inline `complexType`s of `builder`, `forEach`, `forLoop`, `if`, and `else`.

### Why it's a problem

`xs:any namespace="##targetNamespace"` semantically means "any element from
the XWidget namespace can go here." Schema processors are correct to allow
any such element — but for *completion* purposes, many language servers
(including LemMinX, the XML LSP that powers Red Hat XML in VSCode) don't
enumerate all elements in the namespace when the cursor is on a bare `<`.

Concrete observed behavior in VSCode with the current XSD:

- Type `<` → only built-in editor snippets appear (`<!--`, `<![CDATA[`)
- Type `<C` → still no schema completions
- Type `<Co` → finally `Column`, `Controller`, etc. appear

In IntelliJ this works correctly because IntelliJ's XML editor enumerates
namespaces under wildcards. LemMinX does not. We can't change LemMinX's
behavior, but we can write the schema in a way that doesn't depend on it.

### The fix

Define a single `xs:group` listing every top-level concrete element by
reference, and replace every `xs:any namespace="##targetNamespace"` with a
`xs:group ref="..."`:

```xml
<xs:group name="widgetChoice">
    <xs:choice>
        <xs:element ref="builder"/>
        <xs:element ref="callback"/>
        <xs:element ref="debug"/>
        <xs:element ref="forEach"/>
        <xs:element ref="forLoop"/>
        <xs:element ref="fragment"/>
        <xs:element ref="if"/>
        <xs:element ref="else"/>
        <xs:element ref="var"/>
        <xs:element ref="Controller"/>
        <xs:element ref="DynamicBuilder"/>
        <xs:element ref="EventListener"/>
        <xs:element ref="List"/>
        <xs:element ref="Map"/>
        <xs:element ref="MediaQuery"/>
        <xs:element ref="ValueListener"/>
        <xs:element ref="Column"/>
        <xs:element ref="Row"/>
        <xs:element ref="Text"/>
        <xs:element ref="Text.rich"/>
        <!-- ... every other generated and built-in widget ... -->
    </xs:choice>
</xs:group>
```

Then every `xs:any namespace="##targetNamespace" minOccurs="X" maxOccurs="Y"/>`
becomes `xs:group ref="widgetChoice" minOccurs="X" maxOccurs="Y"/>`. Preserve
the original `minOccurs` and `maxOccurs` from each `xs:any` site — they vary
(`objectType` uses `minOccurs="0"`, `builder`/`forEach`/`forLoop`/`if`/`else`
use `minOccurs="1"`).

### Important: the group contains only references, not definitions

The group entries use `<xs:element ref="Column"/>` — just the name. The full
`<xs:element name="Column">...definition with attributes, types, and
documentation...</xs:element>` declarations stay exactly where they are
today, defined once at the top level of the schema. The group references
them by name; it does not duplicate them.

How XSD's ref/def model works:

- `<xs:element name="Column">` at the top level is a **definition**. It
  declares what `Column` is and makes it a globally usable element.
- `<xs:element ref="Column"/>` is a **reference**. It says "an instance of
  the previously-defined `Column` can appear here." All the schema metadata
  (attributes, docs, type) is resolved through the ref to the definition —
  not redeclared.

This is the same pattern as forward declarations in C/C++: the ref is the
declaration, the named top-level element is the implementation. They work
together; you only define each widget once.

So the change to xwidget_builder's emit logic is small:

1. **Add a new section** that emits the group with one `<xs:element ref="..."/>`
   line per known widget. Just a flat list of names, trivial to generate.
2. **Replace `<xs:any namespace="##targetNamespace" .../>`** with
   `<xs:group ref="widgetChoice" .../>` in `objectType`, `listItemType`,
   `mapEntryType`, `paramType`, and the inline complex types of `builder`,
   `forEach`, `forLoop`, `if`, and `else` (preserving min/maxOccurs from
   each site).

The existing top-level `<xs:element name="Column">...</xs:element>` blocks
and every other widget definition stay exactly as they are. The full
attribute lists, type bindings, and documentation blocks are untouched.

### Why this is O(N) not O(N²)

The cartesian-product fear is real but doesn't apply here because the choice
is shared. With ~200 widget types, each parent type doesn't list 200 children
itself — every parent just references the one shared group. Schema size
grows linearly with widget count, not quadratically.

### Decision point: do we need to support undeclared/custom tags?

The original `xs:any namespace="##targetNamespace"` accepts ANY element from
the XWidget namespace, including elements not declared anywhere in the
schema. The `xs:group ref="widgetChoice"` replacement only accepts elements
explicitly listed in the group. This is a semantic narrowing that may or
may not matter for XWidget — depends on whether any valid fragment XML uses
tags that aren't in the generated inflater spec.

**Examples of "custom tags" that might exist outside the inflater spec:**

- Parser-resolved scaffolding tags (handled before widget construction, not
  part of the inflater registry)
- Macro / template / composite-component tags if XWidget has anything like
  JSF composite components or Tiles definitions
- Anything else that's authored in fragment XML but resolved by something
  other than the generated inflaters

If no such tags exist, the simple `xs:group` replacement (current writeup)
is correct and complete.

If such tags do exist, use the combined pattern — group AND wildcard
together inside an `xs:choice`:

```xml
<xs:complexType name="objectType">
    <xs:choice minOccurs="0" maxOccurs="unbounded">
        <xs:group ref="widgetChoice"/>
        <xs:any namespace="##targetNamespace"
                processContents="lax"/>
    </xs:choice>
</xs:complexType>
```

This is structurally legal XSD. `xs:choice` accepts both `xs:group ref` and
`xs:any` as alternatives. Validation tolerates undeclared elements (same as
today's `xs:any` behavior). The group's listed elements are the ones the
schema knows about explicitly.

**Caveat: needs verification before shipping.** The `xs:group`-only pattern
was verified to work in LemMinX during the original investigation. The
combined pattern (group + any in a choice) was NOT tested — it's possible
that LemMinX still suppresses enumeration when an `xs:any` wildcard sits
alongside the group, falling back to the wildcard semantics. Before
adopting the combined pattern, test by hand-editing the generated XSD to
the combined form and confirming bare-`<` completion in VSCode still shows
all listed widgets. If completion regresses, you have to choose:

- Keep `xs:group` alone → great completion, lose the escape hatch
- Keep combined pattern → preserve escape hatch, may lose completion
- Keep `xs:any` alone (today's behavior) → preserve escape hatch, no
  completion improvement

When you implement this in xwidget_builder, look at the actual code first
to identify whether custom-tag support is in use anywhere. The right answer
falls out of that.

### What to leave alone

- The `<xs:element name="fragment">` definition has its own custom
  `<xs:choice>` listing locally-declared `forEach`, `if`, and `param`. Don't
  replace this with the group reference — it's intentionally restrictive.
- Elements with no child content model (`debug`, `var`, `callback`) need no
  changes.
- The `<xs:anyAttribute processContents="lax"/>` on `fragment` is for
  attributes, not elements. Don't touch.

### Verification

Tested by hand-editing a copy of the generated XSD, replacing `xs:any` with
the group reference pattern. After this change:
- Typing `<` inside any widget tag immediately shows all widget elements
- Typing `<C` filters to widgets starting with C
- Validation still correctly rejects elements not in the choice list

## Fix 2 — Escape HTML in `xs:documentation` blocks (or wrap in CDATA)

### Current behavior

The `xs:documentation` blocks contain raw HTML for formatting:

```xml
<xs:attribute name="mainAxisAlignment" type="MainAxisAlignmentAttributeType">
    <xs:annotation>
        <xs:documentation xml:lang="en">
<p>How the children should be placed along the main axis.</p><br/>
<p>For example, [MainAxisAlignment.start], the default, places the children
at the start (i.e., the left for a [Row] or the top for a [Column]) of the
main axis.</p><br/>
        </xs:documentation>
    </xs:annotation>
</xs:attribute>
```

Note the bare `<p>` and `<br/>` tags. The generated XSD declares the default
namespace as `http://www.appfluent.us/xwidget`, so per XML rules these `<p>`
and `<br/>` elements are interpreted as XWidget-namespace elements named `p`
and `br` — which obviously don't exist. The XSD is technically still
well-formed XML (because `<xs:documentation>` accepts any well-formed mixed
content), but the embedded HTML is being misinterpreted by schema processors.

### Why it's a problem

Observed behavior in VSCode with the current XSD: hovering over any element
or attribute does **nothing** — no popup appears, no spinner shows. LemMinX's
hover provider extracts the documentation content but its renderer can't
make sense of the bare HTML tags as XWidget-namespace elements and silently
returns no content.

After replacing the bare HTML with escaped entities (`&lt;p&gt;` instead of
`<p>`), hover documentation appears immediately and renders the HTML as
rich markdown (paragraph breaks, code formatting, lists).

### The fix — two options

**Option A: Escape the HTML.** Replace `<` with `&lt;` and `>` with `&gt;`
in the body of every `<xs:documentation>` block:

```xml
<xs:documentation xml:lang="en">
&lt;p&gt;How the children should be placed along the main axis.&lt;/p&gt;&lt;br/&gt;
&lt;p&gt;For example, [MainAxisAlignment.start], the default, places...&lt;/p&gt;&lt;br/&gt;
</xs:documentation>
```

**Option B: Wrap in CDATA.** Surround the body with `<![CDATA[...]]>`:

```xml
<xs:documentation xml:lang="en"><![CDATA[
<p>How the children should be placed along the main axis.</p><br/>
<p>For example, [MainAxisAlignment.start], the default, places...</p><br/>
]]></xs:documentation>
```

Both produce the same effective behavior. CDATA is more readable in the raw
XSD but slightly more verbose; escaping is uglier in the source but doesn't
need any wrapping. Either fixes hover.

### Verification

Tested by hand-editing the XSD with escaped HTML. Hover over `Column` shows
the description. Hover over `mainAxisAlignment` shows the attribute docs.
Hover over enum values like `mainAxisAlignment="start"` shows enum-value
documentation.

## Test verification setup

To verify these fixes locally before wiring them into xwidget_builder's
generation logic:

1. Take the current generated `xwidget_schema.g.xsd`
2. Apply Fix 1 (xs:group)
3. Apply Fix 2 (escape HTML)
4. Open a fragment XML file in VSCode with the Red Hat XML extension installed
5. Test: bare `<` inside a widget should show all widgets; hover over any tag
   or attribute should show docs

This was the manual verification process used to confirm both fixes work.
The Flutter XWidget VSCode extension already wires up the generated schema
via `xml.fileAssociations` in workspace settings, so no additional setup is
needed — the file just needs to be at the project root with its standard
filename.

## Out of scope (separate concern)

There's a third nice-to-have improvement that's NOT an xwidget_builder change
but worth noting:

**LemMinX doesn't register space as a completion trigger character.** Typing
a space inside an opening tag (like `<Column |>`) doesn't auto-fire the
attribute completion popup — you have to either type one letter or press
Ctrl+Space (or Cmd+I on macOS). This is a `vscode-xml` / LemMinX upstream
limitation. Could be filed as a feature request on
`github.com/redhat-developer/vscode-xml` if it becomes annoying enough, but
there's nothing to do on the xwidget_builder side.
