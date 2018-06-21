
use strict;
my $has_bignum;
BEGIN {
  eval q| require Math::BigInt |;
  $has_bignum = $@ ? 0 : 1;
}
use Test::More $has_bignum
  ? (tests => 13)
  : (skip_all => "Can't load Math::BigInt");
use Cpanel::JSON::XS;
use Devel::Peek;

my $v = Math::BigInt->VERSION;
$v =~ s/_.+$// if $v;

my $fix =  !$v ? '+'
  : $v < 1.6 ? '+'
  : '';

my $json = new Cpanel::JSON::XS;

$json->allow_nonref->allow_bignum;
$json->convert_blessed->allow_blessed;

my $num  = $json->decode(q|100000000000000000000000000000000000000|);

isa_ok($num, 'Math::BigInt');
is("$num", $fix . '100000000000000000000000000000000000000', 'decode bigint')
  or Dump ($num);

my $e = $json->encode($num);
is($e, $fix . '100000000000000000000000000000000000000', 'encode bigint')
    or Dump( $e );

$num  = $json->decode(q|2.0000000000000000001|);
isa_ok($num, 'Math::BigFloat');

is("$num", '2.0000000000000000001', 'decode bigfloat') or Dump $num;
$e = $json->encode($num);
is($e, '2.0000000000000000001', 'encode bigfloat') or Dump $e;

$num = $json->decode(q|[100000000000000000000000000000000000000]|)->[0];

isa_ok( $num, 'Math::BigInt' );
is(
    "$num",
    $fix . '100000000000000000000000000000000000000',
    'decode bigint inside structure'
) or Dump($num);

$num = $json->decode(q|[2.0000000000000000001]|)->[0];
isa_ok( $num, 'Math::BigFloat' );

is( "$num", '2.0000000000000000001', 'decode bigfloat inside structure' )
  or Dump $num;

my $bignan = Math::BigInt->new("NaN");
#Dump $bignan;
my $nan = $json->encode($bignan);
is( "$nan", 'null', 'nan default' );
$nan = $json->stringify_infnan(0)->encode($bignan);
is( "$nan", 'null', 'nan null' );
$nan = $json->stringify_infnan(3)->encode($bignan);
is( "$nan", 'nan', 'nan stringify' );
