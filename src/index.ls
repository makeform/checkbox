module.exports =
  pkg:
    name: \@makeform/checkbox
    extend: name: \@makeform/common
    host: name: \@grantdash/composer
    i18n:
      en:
        "其它": "Other"
        "other-error": "Other checked, but empty"
        config: other:
          enabled: name: "enable 'other' option", desc: "show an 'other' option when enabled"
      "zh-TW":
        "其它": "其它"
        "other-error": "勾選了其它，但未填"
        config: other:
          enabled: name: "使用「其它」選項", desc: "啟用時，顯示一個額外的「其它」選項"
  init: (opt) ->
    opt.pubsub.on \inited, (o = {}) ~> @ <<< o
    opt.pubsub.fire \subinit, mod: mod.call @, opt

mod = ({root, ctx, data, parent, t, i18n, host}) ->
  {ldview} = ctx
  lc = {value: {list: [], other: {enabled: false, text: ""}}}
  id = "_#{Math.random!toString(36)substring(2)}"
  hitf = ~> @hitf
  getv = (t) ~> if typeof(t) == \string => t else t?value or hitf!totext(t?label)
  inside = (v) ~> v in (lc.values or []).map(-> getkey it)
  keygen = -> "#{Date.now!}-#{keygen.idx = (keygen.idx or 0) + 1}-#{Math.random!toString(36)substring(2)}"
  getkey = -> it.key or getv(it)
  @client = ->
    minibar: []
    meta: config: other:
      enabled: type: \boolean, name: "config.other.enabled.name", desc: "config.other.enabled.desc"
    render: ~> @widget.mod.child.view.render!
    sample: ~> config: values: [
      * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Option 1'
      * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Option 2'
      * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Option 3'
      ]
  init: ->
    tolabel = (s) ->
      r = (lc.values or []).filter(-> getkey(it) == s).0
      r = if r and r.label => r.label else r
      if typeof(r) == \object => return hitf!totext(r)
      return if r => t(r) else if typeof(s) == \string => t(s) else s
    remeta = ~>
      lc.other = @mod.info.config.{}other
      lc.values = (@mod.info.config or {}).values or []
      lc.viewopt = (@mod.info.config or {}).view or {}
    remeta!
    @on \meta, ~> remeta!
    @on \change, (v) ~>
      lc.value = (v or {})
      lc.value.list = lc.value.[]list.filter -> inside(it)
      @mod.child.view.render <[input option other-text other-check]>

    _update = (v = {}) ~>
      if !lc.value => lc.value = {}
      if v.list? => lc.value.list = v.list 
      lc.value.list = lc.value.list.filter -> inside(it)
      if v.other =>
        if v.other.enabled? => lc.value.{}other.enabled = v.other.enabled
        if v.other.text? => lc.value.{}other.text = v.other.text
      @value lc.value

    @mod.child.view = view = new ldview do
      root: root
      action:
        click:
          "other-prompt": hitf!edit obj: ({ctx}) ->
            o = hitf!get!{}config{}other
            o.prompt = if typeof(o.prompt) == \string => {} else (o.prompt or {})
          "other-check": ({node}) -> _update {other: {enabled: !!node.checked }}
          add: ({node, views}) ~>
            new-entry = key: keygen!, label: hitf!wrap "#{i18n.language}": 'Untitled'
            hitf!get!{}config[]values.push new-entry
            hitf!set!
            views.0.render!
        input: "other-text": ({node}) -> _update {other: {text: node.value}}
      handler:
        "other-prompt": hitf!render obj: ~>
          (if !(p = hitf!get!?config?other?prompt) => ''
          else if typeof(p) != \string => p else p) or \其它
        content: ({node}) ~>
          txt = if @is-empty! => 'n/a' else (@content! or []).map(->tolabel(it)).join(', ') or 'n/a'
          node.textContent = txt
          hidden = !!lc.viewopt.mode and lc.viewopt.mode != \text
          node.classList.toggle \d-none, hidden
        input: ({node}) ~>
          node.classList.toggle \text-danger, @status! == 2
          show = lc.viewopt.mode and lc.viewopt.mode == \full
          node.classList.toggle \m-edit, !show
        other: ({node}) ~> node.classList.toggle \d-none, !lc.other.enabled
        "other-check": ({node}) ~> 
          if !@mod.info.meta.readonly => node.removeAttribute \disabled
          else node.setAttribute \disabled, null
          node.checked = !!lc.{}value.{}other.enabled
        "other-text": ({node}) ~>
          if !@mod.info.meta.readonly => node.removeAttribute \readonly
          else node.setAttribute \readonly, null
          node.value = (lc.{}value.{}other.text or '')
        option:
          list: ~>
            v = hitf!get!config?values or []
            if Array.isArray(v) => v else if v => [v] else []
          key: -> getkey it
          view:
            action:
              change: checkbox: ({node, ctx}) ~>
                ret = Array.from(root.querySelectorAll 'input[type=checkbox]')
                  .filter -> !!it.checked
                  .map -> it.value
                v = {list: ret}
                _update v
              click:
                "@": ({node, evt}) ->
                  # label dynamics force us to prevent propagation for clicking on editor.
                  if !(node.parentNode and (n = ld$.find(node.parentNode,'[ld=editor]',0))) => return
                  evt.stopPropagation!
                  evt.preventDefault!
                remove: ({node, ctx, views}) ~>
                  cfg = hitf!get!{}config
                  cfg.values = cfg.[]values.filter -> getkey(it) != getkey(ctx)
                  hitf!set!
                text: hitf!edit {obj: ({ctx}) -> ctx.{}label}
            handler:
              "@": ({node}) ~>
                node.style.flexBasis = if (@mod.info.config or {}).layout == \block => "100%" else ''
              checkbox: ({node, ctx}) ~>
                node.setAttribute \name, id
                node.setAttribute \value, getkey(ctx)
                node.checked = getkey(ctx) in ((lc.value or {}).list or [])
                is-full-mode = lc.viewopt.mode and lc.viewopt.mode == \full
                is-view-mode = @mode! == \view
                readonly = if is-view-mode and is-full-mode => true
                else if !@mod.info.meta.readonly => false else true
                if readonly => node.setAttribute \disabled, ""
                else node.removeAttribute \disabled
              text: hitf!render obj: ({ctx}) -> ctx.label or ctx

  render: -> @mod.child.view.render!
  is-empty: (_v) ->
    v = @content(_v) or []
    v = v.filter ~>
      if inside(it) => return true
      if !_v.{}other.enabled => return false
      return it == _v.other.text
    ret = if Array.isArray(v) => !v.length else !v
    # we consider this widget as 'not empty' if other is checked when `requireOnCheck` is enabled.
    # while it's technically 'empty', this help trigger `validate` below,
    # which will still check if the `requireOnCheck` criteria is met,
    # so widget will still be invalid if it's required.
    if ((@mod.info.config or {}).other or {}).require-on-check and _v and _v.{}other.enabled => return false
    ret
  content: (v = {}) ->
    ret = (v.list or [])
    other = if lc.other.enabled and v.{}other.enabled and v.other.text => [v.other.text] else []
    ret = ret ++ other
  validate: ->
    Promise.resolve!then ~>
      if !((@mod.info.config or {}).other or {}).require-on-check => return
      v = @value!
      # we count on this check for `is-required` since we consider a widget as not empty
      # if it's `other` option is checked (even if the other value isn't filled yet)
      if v and (v.other or {}).enabled and !(v.other or {}).text =>
        return ["other-error"]
      return
