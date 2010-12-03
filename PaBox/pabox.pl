#!/usr/bin/perl


use utf8;
use Encode qw(encode decode);
use XML::Simple;
use LWP::Simple;
use LWP::UserAgent;
use PaBox::Track;
use PaBox::LocationDecoder;
use ITagEdit::ITagWriter;
use ProgressBar::Stack;
use HTTP::Request;
binmode STDOUT, "encoding(utf8)";

my $ii = 1;
for (@ARGV) {
  init_progress(message => "正在初始化下载列表 ... ", count => @ARGV + 0);
  my $list_url = 'http://www.8box.cn/radio/list/';
  if (/^\d+$/) {
    $list_url .= $_;
  } else {
    my ($list_id) =~ /(\d+)\D*$/;
    $list_url .= $list_id;
  } 
  my $list_html = get($list_url);

  my @track_list;
  my $decoder = PaBox::LocationDecoder->new();
  my $i = 0;
  my @track_lines = ($list_html =~ /Player\.add\(.*?\);/g);
  my @cover_lines = ($list_html =~ /class="cover".*?src="(.*?)"/g);
  init_progress(message => "正在初始化下载列表 ... ", count => @track_lines - 5);
  for (@track_lines) {
    $i++;
    my $track = PaBox::Track::parse($_, $cover_lines[$i - 1]);
    $track->title($track->title());
    $track->artist($track->artist());
    $track->album_name($track->album_name());
    push @track_list, $track;    
    update_progress($i);
    if ($i == @track_lines) {
      update_progress($i, "初始化下载列表完成 ... ");
    } else {
      update_progress($i);
    }
  }

  print "\n";

  my $userAgent = LWP::UserAgent->new(agent => 'User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; zh-CN; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12');
  for (@track_list) {
    my $track = $_;
    my $title = $track->title();
    my $artist = $track->artist();
    my $album = $track->album_name();
    my $cover = $track->pic();
    my $location = $track->location();
    my $mp3_file_name = $title;
    $mp3_file_name =~ s#(^\s)|(\s$)##g;
    $mp3_file_name .= ".mp3";
    open my $mp3_file, ">", $mp3_file_name;
    my $request = HTTP::Request->new('GET', $location);
    my $response = $userAgent->head($location);
    my $mp3_size = $response->header("Content-Length");
    init_progress(message => " [ 0.00 KB/s ] [ 大小: " . sprintf("%0.2f", $mp3_size/1024/1024) . " MB] 正在下载 [ $ii. $mp3_file_name ] ... ", count => $mp3_size);
    my $counter = 0;
    my $time = time;
    my $speed = 0.00;
    my $speed_counter = 0;
    $response = $userAgent->request($request, sub {
					 my($data, $resp, $proto) = @_;
					 my $len = length $data;
					 $counter += $len;
					 print $mp3_file $data;
					 my $t = time;
					 if ($counter == $mp3_size) {
					   update_progress($counter, " [ " . sprintf("%0.2f", $speed) . " KB/s ] [ 大小: " . sprintf("%0.2f", $mp3_size / 1024 / 1024) . " MB ] 下载完成 [ $ii. $mp3_file_name ] ... ");
					 } else {
					   if ($t != $time) {
					     $speed = ($counter - $speed_counter) / 1024 / ($t - $time);
					     $time = $t;
					     $speed_counter = $counter;					     
					     update_progress($counter, " [ " . sprintf("%0.2f", $speed) . " KB/s ] [ 大小: " . sprintf("%0.2f", $mp3_size / 1024 / 1024) . " MB ] 正在下载 [ $ii. $mp3_file_name ] ... ");
					   }
					 }
				       });
    eval {
    my $itag_writer = ITagEdit::ITagWriter->new(file_name => $mp3_file_name);
    $itag_writer->write(title => $title, artist => $artist, album => $album, cover => get($cover));
    };
    $ii++;
    print "\n";
    #printf "%s<>%s<>%s<>%s<>%s\n", $title, $artist, $album, $cover, $location;
  }
}
