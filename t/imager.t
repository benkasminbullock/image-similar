use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use Image::Similar 'load_image';
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
eval "use Imager;";
if ($@) {
    plan (skip_all => "Imager not available: $@ error on loading");
}
my $chess100 = Imager->new ();
$chess100->read (file => "$Bin/images/chess/chess-100.png")
    or die $chess100->errstr ();
my $is = load_image ($chess100);
ok ($is);
done_testing ();
exit;
