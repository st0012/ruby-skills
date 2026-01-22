---
name: ruby-resource-map
description: Use when working in a Ruby project - provides authoritative sources for documentation, typing, and tooling
---

# Ruby Knowledge

Authoritative resource map for Ruby development. Use these sources rather than searching broadly.

**Never use these sources:**

- ruby-doc.org
- apidock.com

## Official Documentation

**Primary source:** <https://docs.ruby-lang.org/en/>

### Other Useful Resources

- <https://rubyreferences.github.io/rubychanges/> - Version-by-version changelog with examples
- <https://railsatscale.com/> - Shopify engineering blog (Latest updates on Ruby and its toolings)

### Core & Standard Library

| Term | Meaning |
| ---- | ------- |
| Default gem | Ships with Ruby, cannot uninstall |
| Bundled gem | Ships with Ruby, can uninstall/replace |
| Standard library | Part of Ruby itself, not a gem |

| Version | Documentation | Standard Library |
| ------- | ------------- | ---------------- |
| 3.2 | <https://docs.ruby-lang.org/en/3.2/> | <https://docs.ruby-lang.org/en/3.2/standard_library_rdoc.html> |
| 3.3 | <https://docs.ruby-lang.org/en/3.3/> | <https://docs.ruby-lang.org/en/3.3/standard_library_rdoc.html> |
| 3.4 | <https://docs.ruby-lang.org/en/3.4/> | <https://docs.ruby-lang.org/en/3.4/standard_library_md.html> |
| 4.0 | <https://docs.ruby-lang.org/en/4.0/> | <https://docs.ruby-lang.org/en/4.0/standard_library_md.html> |
| master | <https://docs.ruby-lang.org/en/master/> | <https://docs.ruby-lang.org/en/master/standard_library_md.html> |

## Typing Ecosystem

Two type definition formats exist in Ruby:

- **RBI** - Sorbet's format. Uses Ruby DSL syntax (`sig { ... }`) in `.rb` and `.rbi` files.
- **RBS** - Official Ruby format (Ruby 3.0+). Dedicated syntax in `.rbs` files or inline as comments.

### Sorbet Ecosystem

[Sorbet](https://github.com/sorbet/sorbet) is a static and runtime type checker for Ruby, maintained by Stripe. Key companion tools:

- [Tapioca](https://github.com/Shopify/tapioca) - Generates RBI files for gems and DSLs (Rails, ActiveRecord, etc.)
- [Spoom](https://github.com/Shopify/spoom) - Coverage analysis, strictness bumping, dead code detection, signature migration

### RBS Ecosystem

- [rbs](https://github.com/ruby/rbs) - Official CLI for working with RBS files (prototype, list, methods)
- [Steep](https://github.com/soutaro/steep) - Type checker that uses RBS

### RBS Inline Comments

Sorbet supports RBS-style inline type annotations using `#:` comment syntax. This eliminates the need for separate `.rbi` files or verbose `sig` blocks.

Docs: <https://sorbet.org/docs/rbs-comments>
