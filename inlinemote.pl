use utf8;
package emotes;
my %emotes = ();
my $regex = "";
sub init {
  wee::default("emotes", ":c=┐(￣ー￣)┌ :g=(\\s¬‿¬) :s=┐(´～`；)┌ :i=（´_ゝ`)");
  reload();
}

sub reload {
  %emotes = %{wee::hashGet("emotes")};
  $regex = qr/@{[join '|', map { quotemeta($_) } keys %emotes]}/;
  return weechat::WEECHAT_RC_OK;
}

sub delete {
  reload if (wee::hashDelete('emotes', shift));
}

sub add {
  my ($k, $v) = @_;
  reload if (wee::hashAdd('emotes', $k, $v));
}

sub get {
  return \%emotes;
}

sub apply {
  my $s = shift;
  $s =~ s/($regex)/$emotes{$1}/g;
  return $s;
}
1;

package wee;
# completion
my %compl_callbacks = ();
sub __completion_hook {
  my ($data, $completion_item, $buffer, $completion) = @_;
  if(exists $compl_callbacks{$completion_item}) {
    my $h = {
	  add => sub {
	    weechat::hook_completion_list_add($completion, shift, 0, weechat::WEECHAT_LIST_POS_SORT);
	  }
	};
    &{$compl_callbacks{$completion_item}}($h);
  }
  return weechat::WEECHAT_RC_OK;
}

sub completion {
  my($template, $sub) = @_;
  $template = "wee_tpl_".$template;
  $compl_callbacks{$template} = $sub;
  weechat::hook_completion($template, "", "wee::__completion_hook", "");
  my $conf = wee::getopt("weechat.completion.default_template");
  unless ($conf =~ /(?:^|\|)%\(@{[quotemeta($template)]}\)(?:$|\|)/) {
    my $new = $conf."|%($template)";
	wee::setopt("weechat.completion.default_template", $new);
  }
}

# print
sub print {
  my ($d, $t) = (weechat::color("yellow"), weechat::color("lightgreen"));
  weechat::print(weechat::current_buffer(), weechat::prefix("error").$d."{".$t."wee::".$d."} ".(shift));
}

# general options
sub getopt {
  return weechat::config_string(weechat::config_get(shift));
}

sub setopt {
  my ($option, $value) = @_;
  my $rc = weechat::config_option_set(weechat::config_get($option), $value, 1);
  if($rc == weechat::WEECHAT_CONFIG_OPTION_SET_ERROR) {
    wee::print(weechat::color("red")."failed to change $option to $value");
	return 0;
  }
  if($rc eq weechat::WEECHAT_CONFIG_OPTION_SET_OK_CHANGED) {
	wee::print(weechat::color("green")."changed $option to $value");
  }
  return 1;
}
# hashes
sub deserializeHash {
  my %hash = map { my @k = map {unescape($_)} split "="; ($k[0],$k[1]); } split " ", shift;
  return \%hash;
}

sub unescape {
  my $x = shift;
  my %r = ("\\\\"=>"\\", "\\e"=>"=", "\\s" =>" ");
  $x =~ s/(\\\\|\\e|\\s)/$r{$1}/g;
  return $x;
}

sub escape {
  my $x = shift;
  my %r = ("\\"=>"\\\\", "="=>"\\e", " "=>"\\s");
  $x =~ s/(\\|=| )/$r{$1}/g;
  return $x;
}

sub serializeHash {
  my $hashref = shift;
  return join " ", map { escape($_) . "=" . escape($hashref->{$_}) } keys %{$hashref};
}

sub hashGet {
  return deserializeHash wee::get(shift);
}

sub hashDelete {
  my ($prop, $key) = @_;
  my %h=%{wee::hashGet($prop)};
  if(exists $h{$key}) {
    delete $h{$key};
    wee::set($prop, serializeHash(\%h));
    return 1;
  }
  return 0;
}

# arrays
sub hashAdd {
  my ($prop, $key, $value) = @_;
  my %h=%{wee::hashGet($prop)};
  if(not exists $h{$key} or $h{$key} ne $value) {
    $h{$key} = $value;
    wee::set($prop, serializeHash(\%h));
    return 1;
  }
  return 0;
}

sub arrayDelete {
  my ($prop,$index) = @_;
  my @a = @{wee::arrayGet($prop)};
  return 0 if($index<0||$index>=scalar(@a));
  splice(@a, $index, 1);
  wee::set($prop,join" ",@a);
  return 1;
}

sub arrayAdd {
  ($prop,$value) = @_;
  my @a=@{wee::arrayGet($prop)};
  if(scalar(grep { $a[$_] eq $value } 0..$#a) == 0){
   push(@a,$value);
   wee::set($prop,join" ",@a);
   return 1;
  }
  return 0;
}

sub arrayGet {
  my @a=split(/\s+/,wee::get(shift));
  return \@a;
}

# script options
sub default { weechat::config_set_plugin($_[0], $_[1]) if !weechat::config_is_set_plugin($_[0]); }
sub get { return weechat::config_get_plugin($_[0]); }
sub set { weechat::config_set_plugin($_[0], $_[1]); }
1;
package ie;
my $SCRIPT_NAME = "inlinemote";
my $PLUGIN_PREFIX = "plugins.var.perl.".$SCRIPT_NAME;
weechat::register($SCRIPT_NAME, "voldenet", "0.1", "Whatever", "replaces inline strings with given replacements", "", "");
weechat::hook_command("ie", "<action> <text|file> <replacement>", qq {
{text} can be anything, but it must not contain spaces

add {text} {replacement} - adds a replacement
remove {text} - removes given replacement if it exists
list - lists the replacements in current buffer
on - enables the inline replacement (default)
off - disables the inline replacement
load {file} - loads emotes from a file
save {file} - stores emotes to a file
save -f {file} - stores emotes to a file, forces overwrite if file exists
}, "", "", "ie::manage", "");
weechat::hook_modifier("input_text_for_buffer", "ie::input", "");
weechat::hook_config($PLUGIN_PREFIX.".*", "ie::reload", "");
my $disable = 0;
wee::default("disable",0);
emotes::init();
reload();

wee::completion ($SCRIPT_NAME, sub {
  my $add = (shift)->{'add'};
  &{$add}($_) for keys %{emotes::get()};
});

sub input {
  my ($data, $modifier_name, $buffer, $string) = @_;
  if(!$disable){
    return $string if $string =~ m[^/(?!(?:me|say)\s+)];
    $string = emotes::apply($string);
  }
  return $string;
}

sub load {
  my ($buffer, $fn) = @_;
  open my $h, '<', $fn or die "Unable to open >$fn: $!";
  while(<$h>) {
    emotes::add $1, $2 if /^(\S+) (.*)$/;
  }
  weechat::print($buffer, "[inlinemote]\tloading from file ".$fn." completed");
  close $h;
}

sub save {
  my ($buffer, $force, $fn) = @_;
  die "file $fn exists and force wasn't used" unless $force or not -e $fn;
  open my $h, '>', $fn;
  my %el = %{emotes::get()};
  for(keys %el) {
    print $h $_.' '.$el{$_}."\n";
  }
  weechat::print($buffer, "[inlinemote]\tsaving to file ".$fn." completed");
  close $h;
}

sub manage {
  my($data, $buffer, $args) = @_;
  if($args =~ /^on/) {
    wee::set('disable',0);
  }
  if($args =~ /^off/) {
    wee::set('disable',1);
  }
  if($args =~ /^remove (.*)$/) {
    emotes::delete($1);
  }
  if($args =~ /^add (\S+) (.*)$/) {
    emotes::add($1, $2);
  }
  if($args =~ /^save (?:-(\S+)\s+)?(.+)$/) {
    save($buffer, ($1 || '') eq 'f', $2);
  }
  if($args =~ /^load (.+)$/) {
    load($buffer, $1);
  }
  if($args =~ /^list$/) {
    my %el = %{emotes::get()};
    weechat::print($buffer, "EMOTES:");
    for(keys %el) {
      weechat::print($buffer, "> ".$_." ".$el{$_});
    }
  }
}

sub reload {
  emotes::reload();
  $disable = wee::get("disable") eq "1";
}
