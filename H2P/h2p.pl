#!/usr/bin/perl

use Lingua::Han::PinYin;
my $h2p = Lingua::Han::PinYin->new();
while(<>) {
    print $h2p->han2pinyin($_);
}
