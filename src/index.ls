module.exports =
  pkg:
    name: "@makeform/checkbox", extend: name: '@makeform/common'
    i18n:
      en:
        "其它": "Other"
        "other-error": "Other checked, but empty"
      "zh-TW":
        "其它": "其它"
        "other-error": "勾選了其它，但未填"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)
mod = ({root, ctx, data, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {value: {list: [], other: {enabled: false, text: ""}}}
  id = "_#{Math.random!toString(36)substring(2)}"
  getv = (t) -> if typeof(t) == \object => t.value else t
  getlabel = (s) -> if typeof(s) == \object => t(s.label) else t(s)
  tolabel = (s) ->
    r = (lc.values or []).filter(-> getv(it) == s).0
    r = if r and r.label => r.label else r
    return if r => t(r) else s

  inside = (v) ~> v in (lc.values or []).map(-> getv it)
  init: (base) ->
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
        click: "other-check": ({node}) -> _update {other: {enabled: !!node.checked }}
        input: "other-text": ({node}) -> _update {other: {text: node.value}}
      text:
        "other-prompt": ({node}) ~>
          if (lc.other or {}).prompt => return t(that)
          else return t("其它")
      handler:
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
          list: -> lc.values or []
          key: -> getv it
          view:
            action: change: checkbox: ({node, ctx}) ~>
              ret = Array.from(root.querySelectorAll 'input[type=checkbox]')
                .filter -> !!it.checked
                .map -> it.value
              v = {list: ret}
              _update v
            handler:
              "@": ({node}) ~>
                node.style.flexBasis = if (@mod.info.config or {}).layout == \block => "100%" else ''
              checkbox: ({node, ctx}) ~>
                node.setAttribute \name, id
                node.setAttribute \value, getv(ctx)
                node.checked = getv(ctx) in ((lc.value or {}).list or [])
                is-full-mode = lc.viewopt.mode and lc.viewopt.mode == \full
                is-view-mode = @mode! == \view
                readonly = if is-view-mode and is-full-mode => true
                else if !@mod.info.meta.readonly => false else true
                if readonly => node.setAttribute \disabled, ""
                else node.removeAttribute \disabled
            text: text: ({node, ctx}) -> getlabel(ctx)

  render: -> @mod.child.view.render!
  is-empty: (_v) ->
    v = @content(_v) or []
    v = v.filter ~>
      if inside(it) => return true
      if !_v.{}other.enabled => return false
      return it == _v.other.text
    ret = if Array.isArray(v) => !v.length else !v
    ret
  content: (v = {}) ->
    ret = (v.list or [])
    other = if lc.other.enabled and v.{}other.enabled and v.other.text => [v.other.text] else []
    ret = ret ++ other
  validate: ->
    Promise.resolve!then ~>
      v = @value!
      if v and (v.other or {}).enabled and !(v.other or {}).text =>
        return ["other-error"]
      return
