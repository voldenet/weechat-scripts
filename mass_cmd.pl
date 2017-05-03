weechat::register("mass_cmd", "voldenet", "0.1", "GPL3", "masskick", "", "");
weechat::hook_command("masscmd", "", "", "", "", "masscmd", "");

sub foreach_infolist(&$$$) {
   my($sub, $name, $ptr, $args) = @_;
   my $list_ptr = weechat::infolist_get($name, $ptr, $args);
   while(weechat::infolist_next($list_ptr)) {
      &{$sub}($list_ptr);
   }
   weechat::infolist_free($list_ptr);
}

sub foreach_nick(&$) {
   my($sub, $buffer) = @_;
   foreach_infolist(sub {
      return if weechat::infolist_integer($_[0], 'visible') == "0";
      my $n = weechat::infolist_string($_[0], 'name');
      return if $n =~ /^\d+\|/;
      &{$sub}($n);
   }, 'nicklist', $buffer, '');
}

sub list_nicks($) {
   my $buffer = shift;
   my @names;
   foreach_nick(sub {
      my $name = shift;
      push(@names, $name);
   }, $buffer);
   return \@names;
}

sub masscmd {
   my($data, $buffer, $args) = @_;
   my $me = weechat::buffer_get_string($buffer, 'localvar_nick');
   my @nicks_to_kick = grep { $_ ne $me } reverse(@{list_nicks $buffer});
   push(@nicks_to_kick, $me);
   for $n (@nicks_to_kick) {
      my $s = $args;
      $s =~ s/{nick}/$n/;
      weechat::command($buffer, $s);
   }
}
