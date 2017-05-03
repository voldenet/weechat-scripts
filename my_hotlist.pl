weechat::register("my_hotlist","voldenet","0.1","GPL3","","","");
weechat::hook_signal("hotlist_changed", "hotlist_changed", "");
sub hotlist_changed { weechat::bar_item_update('my_hotlist'); }
weechat::bar_item_new('(extra)my_hotlist', "my_hotlist_render", "");
weechat::bar_item_update('my_hotlist');
use Data::Dumper;
sub render_one {
  my($no, $item, $is_current) = @_;
  my $prio = $item->{priority};
  my $buffer_pointer = $item->{buffer_pointer};
  #my $name = weechat::buffer_get_string($ptr, "short_name");
  if($is_current) {
    my $name = weechat::buffer_get_string($buffer_pointer, "short_name");
    return weechat::color("lightgreen")."*$no:$name";
  }
  return weechat::color("reset").$no if $prio < 3;
  return weechat::color("red").$no."+";
}

sub my_hotlist_render {
  my ($data, $item, $window, $buffer, $extra_info) = @_;
  my $current_buffer_number = weechat::buffer_get_integer($buffer, 'number');
  my $infolist = weechat::infolist_get('hotlist', '', '');
  my %hotlist;
  $hotlist{$current_buffer_number} = { buffer_pointer => $buffer, priority => 0 };
  while(weechat::infolist_next($infolist))
  {
    my $num = weechat::infolist_integer($infolist, "buffer_number");
    $hotlist{$num} = { priority => weechat::infolist_integer($infolist, "priority"), buffer_pointer => weechat::infolist_pointer($infolist, "buffer_pointer") };;
  }
  weechat::infolist_free($infolist);
  my @l = map { render_one($_, $hotlist{$_}, $current_buffer_number eq $_) } sort { $a <=> $b } keys %hotlist;
  return join(" ", @l);
}
