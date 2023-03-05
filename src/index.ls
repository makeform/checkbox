module.exports =
  pkg:
    name: "@makeform/checkbox", extend: name: '@makeform/common'
    i18n:
      en: "其它": "Other"
      "zh-TW": "其它": "其它"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)
mod = ({root, ctx, data, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {value: {list: [], other: {enabled: false, text: ""}}}
  id = "_#{Math.random!toString(36)substring(2)}"
  init: (base) ->
    remeta = ~>
      lc.other = @mod.info.config.{}other
      lc.values = (@mod.info.config or {}).values or []
    remeta!
    @on \meta, ~> remeta!
    @on \change, (v) ~>
      lc.value = (v or {})
      lc.value.list = lc.value.[]list.filter -> it in lc.values
      @mod.child.view.render <[input option other-text other-check]>

    _update = (v = {}) ~>
      if !lc.value => lc.value = {}
      if v.list? => lc.value.list = v.list 
      lc.value.list = lc.value.list.filter -> it in lc.values
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
        content: ({node}) ~>
          if @is-empty! => 'n/a' else (@content! or []).map(->t(it)).join(', ') or 'n/a'
      handler:
        input: ({node}) ~> node.classList.toggle \text-danger, @status! == 2
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
          key: -> it
          view:
            action: change: checkbox: ({node, ctx}) ~>
              ret = Array.from(root.querySelectorAll 'input[type=checkbox]')
                .filter -> !!it.checked
                .map -> it.value
              v = {list: ret}
              _update v
            handler: checkbox: ({node, ctx}) ~>
              node.setAttribute \name, id
              node.setAttribute \value, ctx
              node.checked = ctx in ((lc.value or {}).list or [])
              if !@mod.info.meta.readonly => node.removeAttribute \disabled
              else node.setAttribute \disabled, null
            text: text: ({node, ctx}) -> t ctx

  render: -> @mod.child.view.render!
  is-empty: (_v) ->
    v = @content(_v) or []
    v = v.filter ~>
      if (it in lc.values) => return true
      if !_v.{}other.enabled => return false
      return it == _v.other.text
    ret = if Array.isArray(v) => !v.length else !v
    ret
  content: (v = {}) ->
    ret = (v.list or [])
    other = if lc.other.enabled and v.{}other.enabled and v.other.text => [v.other.text] else []
    ret = ret ++ other

