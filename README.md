[![Actions Status](https://github.com/kfly8/kote/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/kote/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/kote/main.svg?style=flat)](https://coveralls.io/r/kfly8/kote?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/kote.svg)](https://metacpan.org/release/kote)
# NAME

kote - Type::Tiny based type framework

# SYNOPSIS

```perl
use Types::Standard -types;

use kote CharacterName  => Str & sub { /^[A-Z][a-z]+$/ };
use kote CharacterLevel => Int & sub { $_ >= 1 && $_ <= 100 };

use kote Character => Dict[
    name  => CharacterName,
    level => CharacterLevel,
];

my ($alice, $err) = Character->create({ name => 'Alice', level => 1 });
say $alice->{name}; # Alice
say $err; # undef

my ($bob, $err) = Character->create({ name => 'bob', level => 0 });
say $bob; # undef
say $err; # Error!
```

# DESCRIPTION

Kote - **means "gauntlet"🧤 in Japanese** - is a type framework based on Type::Tiny.
Kote aims to simplify type declarations and value checks in Perl.

## FEATURES

- Simplify Type Declarations

    Type declarations just need to write in one place.

    ```perl
    use kote CharacterName => Str & sub { /^[A-Z][a-z]+$/ };
    ```

- Easy to Check Values

    Only legal values can be created.

    ```perl
    my ($alice, $err) = CharacterName->create('Alice');
    croak $err if $err; # Must handle error!
    ```

- Type::Tiny Based

    The types declared by Kote are based on Type::Tiny, so we can use Type::Tiny's all features.

    ```
    CharacterName->isa('Type::Tiny'); # true
    ```

# CONCEPTS

Kote is inspired by the following book, [Domain Modeling Made Functional](https://pragprog.com/titles/swdddf/).

The phrase "Make illegal states unrepresentable" is a particularly important concept in Kote.
This idea works for dynamically typed languages like Perl too. By clearly stating the legal values, it make to easier to maintain codes.

# DETAILS

## Declare types

Kote provides a syntax for declaring types.

```perl
use kote TYPE_NAME => TYPE_CONSTRAINT;
```

The first argument is a type name, and the second argument is a type constraint.
Type name must begin with an uppercase letter and can only contain alphabetic letter, digits and underscores.
Type constraints must be a Type::Tiny object or something that can be converted to one.

Using Kote inherits [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny) and automatically adds the declared type to `@EXPORT_OK`.
This means you can import types as follows:

```perl
package main;
use My::Character qw(CharacterName);

CharacterName->check('Alice'); # true
```

Order of type declarations is important, child types must be declared before parent types.

```perl
# Bad order
use kote Parent => Dict[ name => Child ];
use kote Child => Str;

# Good order
use kote Child => Str;
use kote Parent => Dict[ name => Child ];
```

## Create value method

The type declared in Kote has a `create` method.

```perl
my ($alice, $err) = Character->create({name => 'Alice', level => 1});
croak $err if $err;
```

The `create` method returns a error message if the given value does not satisfy the type, and returns the value if it does:

```
create(Any $value) -> (Any $value, undef) or (undef, Str $error)
```

If the value is a reference, it will be converted to an immutable:

```
$alice->{name} = 'Bob'; # Error
$alice->{unknown}; # Error
```

An exception is thrown if an error is not handled. Calling the create method in scalar or void context will throw an exception:

```perl
my $alice = Character->create({name => 'Alice', level => 1});
# => Exception: Must handle error!!
```

# TIPS

## Export Functions

You can export functions as well as types by pushing them to `@EXPORT_OK`.

```perl
package My::Character {
    our @EXPORT_OK;
    push @EXPORT_OK, qw(is_alice);

    use kote CharacterName => Str & sub { /^[A-Z][a-z]+$/ };

    sub is_alice($name) { $name eq 'Alice' }
}

package main;
use My::Character qw(CharacterName is_alice);
```

## Skip Check Value

If `$ENV{KOTE_STRICT}` is set to false during the BEGIN phase, the validation of the value and the conversion to make it immutable are skipped. However, be careful not to skip values that need to be validated.

```perl
BEGIN {
    $ENV{KOTE_STRICT} = 0;
}

use kote Name => Str & sub { /^[A-Z][a-z]+$/ };

my ($alice, $err) = Name->create(1234);
$err; # No Error
```

If `$ENV{KOTE_STRICT}` is set to false but you still want to perform validation, you should use the `strictly_create` method instead of the `create` method.

```perl
my ($alice, $err) = Name->strictly_create(1234);
$err; # Error!!
```

# THANKS

Toby Inkster, the author of [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny).

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>
