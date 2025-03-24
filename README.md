# @makeform/checkbox

Checkbox style widget for users to make multiple choices from multiple options.


## Configs

 - `values`: Array of string/objects for options in this widget.
   - when object is used, it contains following fields:
     - `value`: actual value picked
     - `label`: text shown for user to select
 - `other`: default null. An object for config of `other` option, with following fields:
   - `enabled`: default false. should `other` option be shown.
   - `prompt`: default `其它` or `Other`. Prompt text for `other` option.
   - `requireOnCheck`: default false.
     - when true, the `Other` field must be filled when `Other` is checked;
       otherwise, this field will be considered invalid.
 - `layout`: default `inline`. decide how to layout options. possible values: either `inline` or `block`.
 - `view`: view mode related configs.
   - `mode`: either `text` or `full`. default `text`.
     - `text`: options are shown as concated text. `n/a` if no option is chosen.
     - `full`: all options will be shown with checkbox checked for chosen options.


## License

MIT
