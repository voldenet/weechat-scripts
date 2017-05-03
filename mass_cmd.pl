weechat::register("mass_cmd", "voldenet", "0.1", "Whatever", "/mass_cmd /anything {nick}", "", "");
weechat::hook_command("mass_cmd", "", "", "", "", "mass_cmd", "");

sub foreach_infolist($$$&) {
   my($name, $ptr, $args, $fn) = @_;
   my $list_ptr = weechat::infolist_get($name, $ptr, $args);
   while(weechat::infolist_next($list_ptr)) {
      &{$fn}($list_ptr);
   }
   weechat::infolist_free($list_ptr);
}

sub foreach_nick($&) {
   my($buffer, $fn) = @_;
   foreach_infolist 'nicklist', $buffer, '', sub {
      return if weechat::infolist_integer($_[0], 'visible') == "0";
      my $nick = weechat::infolist_string($_[0], 'name');
      return if $nick =~ /^\d+\|/;
      &{$fn}($nick);
   };
}

sub list_nicks($) {
   my $buffer = shift;
   my @names;
   foreach_nick($buffer, sub {
      my $name = shift;
      push(@names, $name);
   });
   return \@names;
}

sub mass_cmd {
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
