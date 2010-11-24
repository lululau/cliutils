#!/usr/bin/perl

use utf8;
use Encode::HanConvert;

binmode STDIN, "encoding(utf8)";
binmode STDOUT, "encoding(utf8)";

while (<>) {
    print trad_to_simp($_);
}
