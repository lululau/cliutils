#!/usr/bin/perl

use utf8;
use Encode::HanConvert;

binmode STDIN, "encoding(utf8)";
binmode STDOUT, "encoding(utf8)";

while (<>) {
    print simp_to_trad($_);
}
