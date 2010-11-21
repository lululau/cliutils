#!/usr/bin/perl

use utf8;
use XML::Simple;
use LWP::Simple;
use PiaMi::Track;
use ITagEdit::ITagWriter;
binmode STDOUT, "encoding(utf8)";

my $xml_ref = XMLin(get("http://www.xiami.com/song/playlist/id/2162710/type/3"), ForceArray => 1);
my @track_list;
if (exists $xml_ref->{trackList}[0]{track}) {  
  for my $track_ref(@{$xml_ref->{trackList}[0]{track}}) {
    push @track_list, PiaMi::Track::parse($track_ref);
  }
}


for (@track_list) {
  my $track = $_;
  my $title = $track->title();
  my $artist = $track->artist();
  my $album = $track->album_name();
  my $cover = $track->pic();
  my $location = $track->location();
  print $location, "\n";
  
#  my $mp3_file_name = $title;
# $mp3_file_name =~ s#(^\s)|(\s$)##g;
#  $mp3_file_name .= ".mp3";
#  open my $mp3_file, ">", $mp3_file_name;
#  print $mp3_file get($location);
#  my $itag_writer = ITagEdit::ITagWriter->new(file_name => $mp3_file_name);
#  $itag_writer->write(title => $title, artist => $artist, album => $album, cover => get($cover));
}
