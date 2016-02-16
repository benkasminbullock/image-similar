package Image::Similar;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw//;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load ('Image::Similar', $VERSION);
1;
