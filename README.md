# weechat-scripts
Some scripts for weechat

- [inlinemote.pl](inlinemote.pl)
  - allows you to use inline text (mostly used for emotes) replacements in weechat and adds autocompletion
  - lists of emotes are saved as `plugins.var.perl.inlinemote.emotes` which allows you to share your emotes without much hassle
  - current defaults are
    - :whatever ¯\\\_(ツ)\_/¯
    - :yay (ﾉ´ｰ`)ﾉ
    - :indifferent （´_ゝ`) 
    - :c ┐(￣ー￣)┌
    - :g ( ¬‿¬)
    - :s ┐(´～`；)┌
    - :i （´_ゝ`)
    
  You can easily add, list and remove combinations:
  `/ie list` - lists all emotes in the buffer
  `/ie add _x :-)` - adds a replacement _x, the emoticon can contain spaces
  `/ie remove _x` - removes replacement _x
  `/ie on` - enables replacements
  `/ie off` - disables replacements
- [mass_cmd.pl](mass_cmd.pl)
  - gives you an ability to invoke a command for all nicks in buffer:
    - `/mass_cmd hello, {nick}`
    - `/mass_cmd /mode #channel +v {nick}`
    
- [my_hotlist.pl](my_hotlist.pl)
  - adds a custom my_hotlist item, use to write your own hotlist style

## License

All my plugins are licensed under the "whatever" license. See [the license](LICENSE) for more information.
