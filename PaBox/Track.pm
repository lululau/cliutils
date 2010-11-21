#!/usr/bin/perl

package PaBox::Track;

use Class::Struct;
use PaBox::LocationDecoder;
use URI::Escape;
use LWP::Simple;

struct PaBox::Track => {
			title => '$',
			song_id => '$',
			album_id => '$',
			album_name => '$',
			object_id => '$',
			object_name => '$',
			insert_type => '$',
			background => '$',
			grade => '$',
			artist => '$',
			location => '$',
			ms => '$',
			lyric => '$',
			pic => '$',
			year => '$'
		       };

sub parse {
  my $track_line = shift;
  my $cover = shift;
  my $track = PaBox::Track->new();
  my $decoder = PaBox::LocationDecoder->new();
  my($title, $location, $artist) = $track_line =~ /Player\.add\(\d*, *"(.*?)", *playerEncode\(decodeURIComponent\("(.*?)"\)\), *"(.*)",.*\);/m;
  $track->title($title);
  $track->artist($artist);  
  $track->location($decoder->decode($location));
  $track->pic("http://www.8box.cn" . $cover);
  my($pic, $album) = fetch_pic_album(title => $title, artist => $artist);
  $track->pic($pic);
  $track->album_name($album);
  return $track;
}

sub fetch_pic_album {
  my $args = {@_};
  my $search_url = 'http://www.xiami.com/search';
  my $search_key = "key";
  my $search_value = "$args->{title} $args->{artist}";
  $search_value =~ s/ /\+/g;
  my $search = $search_url . "?" . $search_key . "=" . uri_escape_utf8($search_value);
  my $search_result_html = get($search);
  my ($line) = $search_result_html =~ /href="(\/song\/\d+?)\/?"/;
  my $song_url = 'http://www.xiami.com'. $line;
  my $song_html = get($song_url);
  my ($album) = $song_html =~ m#<td><a href="/album/\d*" title="">(.*?)</a></td>#;
  my ($pic) = $song_html =~ m#<div class="song_cover">.*?src="(.*?\.jpg)" ?/></a></div>#;
  return ($pic, $album);
}

1;
