use Test2::V0;

use Types::Standard qw(Dict Str Int Enum ArrayRef InstanceOf Tuple);

BEGIN {
    $ENV{PERL_CASEVAL_STRICT} = 1;
}

use caseval Human => Dict[
    name => Str,
    age => Int,
];

is Human, object {
    prop blessed => 'Type::Tiny';
    call display_name => 'Dict[age=>Int,name=>Str]';
}, 'Human is a Type::Tiny object';

my $human = Human::val(name => 'John', age => 42);
is $human, { name => 'John', age => 42 }, 'Human::val returns a hashref';

subtest 'PERL_CASEVAL_STRICT is enabled' => sub {
    like dies {
       $human->{foo};
    }, qr/Attempt to access disallowed key 'foo'/, 'Human::val is locked';

    like dies {
        $human->{name} = 'Jane';
    }, qr/Modification of a read-only value attempted/, 'Human::val is immutable';

    like dies {
        Human::val(foo => '');
    }, qr/Reference \{"foo" => ""\} did not pass type constraint/, 'Human::val validates';
};

subtest 'Check valid caseval name' => sub {
    my @invalid_names = (
        'str'        => "caseval name 'str' is not CamelCase",
        'int'        => "caseval name 'int' is not CamelCase",
        'dash-case'  => "caseval name 'dash-case' is not CamelCase",
        'snake_case' => "caseval name 'snake_case' is not CamelCase",
        '_Foo'       => "caseval name '_Foo' is not CamelCase",
        '1Foo'       => "caseval name '1Foo' is not CamelCase",
        'BEGIN'      => "caseval name 'BEGIN' is forbidden",
        'CHECK'      => "caseval name 'CHECK' is forbidden",
        'DESTROY'    => "caseval name 'DESTROY' is forbidden",
        'END'        => "caseval name 'END' is forbidden",
        'INIT'       => "caseval name 'INIT' is forbidden",
        'UNITCHECK'  => "caseval name 'UNITCHECK' is forbidden",
        'AUTOLOAD'   => "caseval name 'AUTOLOAD' is forbidden",
        'STDIN'      => "caseval name 'STDIN' is forbidden",
        'STDOUT'     => "caseval name 'STDOUT' is forbidden",
        'STDERR'     => "caseval name 'STDERR' is forbidden",
        'ARGV'       => "caseval name 'ARGV' is forbidden",
        'ARGVOUT'    => "caseval name 'ARGVOUT' is forbidden",
        'ENV'        => "caseval name 'ENV' is forbidden",
        'INC'        => "caseval name 'INC' is forbidden",
        'SIG'        => "caseval name 'SIG' is forbidden",
    );

    while (my ($name, $error) = splice @invalid_names, 0, 2) {
        eval "use caseval '$name' => Str;";
        like $@, qr/^$error/, "$error";
    }

    eval "use caseval;";
    like $@, qr/^caseval name is not given/, "caseval name is not given";

    eval "use caseval Human => Str;";
    like $@, qr/^caseval name 'Human' is already defined./, "caseval name 'Human' is already defined.";
};

use caseval Foo => Str;
my $foo = Foo::val('foo');
is $foo, 'foo', 'Foo::val returns a string';

use caseval Bar => Enum['foo', 'bar'];
my $bar = Bar::val('bar');
is $bar, 'bar', 'Bar::val returns a string';

ok dies {
    Bar::val('baz');
}, 'Bar::val dies if the value is not in the enum';

use caseval Baz => ArrayRef[Int];
my $baz = Baz::val(1, 2, 3);
is $baz, [1, 2, 3], 'Baz::val returns an arrayref';

ok dies {
    Baz::val(1, 'foo', 3);
}, 'Baz::val dies if the value is not in the arrayref';

use caseval Qux => Dict[foo => Str] | Dict[bar => Str];
is Qux::val(foo => 'foo'), { foo => 'foo' }, 'Qux::val returns a hashref';
is Qux::val(bar => 'bar'), { bar => 'bar' }, 'Qux::val returns a hashref';

ok dies {
    Qux::val(baz => 'baz');
}, 'Qux::val dies if the value is not in the dict';

use caseval Quux => Str & sub { length $_ > 1 };
is Quux::val('foo'), 'foo', 'Quux::val returns a string';

ok dies {
    Quux::val('f');
}, 'Quux::val dies if the value is not in the coderef';

use caseval A => InstanceOf['Type::Tiny'];
my $t = A::val(name => 'Hello');
isa_ok $t, 'Type::Tiny';
is $t, 'Hello';

use caseval Tu => Tuple[Int, Str];
is Tu::val(1, 'foo'), [1, 'foo'], 'Tu::val returns an arrayref';

done_testing;
