defmodule Surface.DirectivesTest do
  use ExUnit.Case, async: true

  import Surface
  import ComponentTestHelper

  defmodule Div do
    use Surface.Component

    def render(assigns) do
      ~H"""
      <div>{{ @inner_content.([]) }}</div>
      """
    end
  end

  defmodule DivWithProps do
    use Surface.Component

    property(class, :string)
    property(hidden, :boolean)
    property(content, :string)

    def render(assigns) do
      ~H"""
      <div class={{ @class, hidden: @hidden, block: !@hidden }}>
        {{ @content }}
      </div>
      """
    end
  end

  describe ":props for a component" do
    test "passing keyword list of props" do
      assigns = %{}

      code = """
      <DivWithProps :props={{ class: "text-xs", hidden: false, content: "dynamic props content" }} />
      """

      assert render_live(code, assigns) =~ """
             <div class="text-xs block">
               dynamic props content
             </div>
             """
    end

    test "static props override dynamic props" do
      assigns = %{}

      code = """
      <DivWithProps content="static content" :props={{ class: "text-xs", hidden: false, content: "dynamic props content" }} />
      """

      assert render_live(code, assigns) =~ """
             <div class="text-xs block">
               static content
             </div>
             """
    end

    test "using an assign" do
      assigns = %{opts: %{class: "text-xs", hidden: false, content: "dynamic props content"}}

      code = """
      <DivWithProps :props={{ @opts }} />
      """

      assert render_live(code, assigns) =~ """
             <div class="text-xs block">
               dynamic props content
             </div>
             """
    end
  end

  describe ":attrs in html tags" do
    test "passing a keyword list" do
      assigns = %{}

      code = ~H"""
      <div class="myclass" :attrs={{ id: "myid" }}>
        Some Text
      </div>
      """

      assert render_static(code) =~ """
             <div id="myid" class="myclass">
               Some Text
             </div>
             """
    end

    test "passing a map" do
      assigns = %{}

      code = ~H"""
      <div class="myclass" :attrs={{ %{id: "myid"} }}>
        Some Text
      </div>
      """

      assert render_static(code) =~ """
             <div id="myid" class="myclass">
               Some Text
             </div>
             """
    end

    test "using an assign" do
      assigns = %{div_props: [id: "myid", "aria-label": "A div"]}

      code = ~H"""
      <div class="myclass" :attrs={{ @div_props }}>
        Some Text
      </div>
      """

      assert render_static(code) =~ """
             <div aria-label="A div" id="myid" class="myclass">
               Some Text
             </div>
             """
    end

    test "with boolean properties" do
      assigns = %{}

      code = ~H"""
      <div class="myclass" :attrs={{ disabled: true }}>
        Some Text
      </div>
      """

      assert render_static(code) =~ """
             <div disabled class="myclass">
               Some Text
             </div>
             """
    end

    test "static properties override dyanmic properties" do
      assigns = %{}

      code = ~H"""
      <div class="myclass" id="static-id" :attrs={{ id: "dynamic-id" }}>
        Some Text
      </div>
      """

      assert render_static(code) =~ """
             <div class="myclass" id="static-id">
               Some Text
             </div>
             """
    end
  end

  describe ":for" do
    test "in components" do
      assigns = %{items: [1, 2]}

      code = """
      <Div :for={{ i <- @items }}>
        Item: {{i}}
      </Div>
      """

      assert render_live(code, assigns) =~ """
             <div>
               Item: 1
             </div><div>
               Item: 2
             </div>
             """
    end

    test "in html tags" do
      assigns = %{items: [1, 2]}

      code = """
      <div :for={{ i <- @items }}>
        Item: {{i}}
      </div>
      """

      assert render_live(code, assigns) =~ """
             <div>
               Item: 1
             </div><div>
               Item: 2
             </div>
             """
    end

    test "in void html elements" do
      assigns = %{}

      code = ~H"""
      <br :for={{ _ <- [1,2] }}>
      """

      assert render_static(code) == """
             <br><br>
             """
    end

    test "with larger generator expression" do
      assigns = %{items1: [1, 2], items2: [3, 4]}

      code = """
      <div :for={{ i1 <- @items1, i2 <- @items2, i1 < 4 }}>
        Item1: {{i1}}
        Item2: {{i2}}
      </div>
      """

      assert render_live(code, assigns) =~ """
             <div>
               Item1: 1
               Item2: 3
             </div>\
             <div>
               Item1: 1
               Item2: 4
             </div>\
             <div>
               Item1: 2
               Item2: 3
             </div>\
             <div>
               Item1: 2
               Item2: 4
             </div>
             """
    end
  end

  describe ":if" do
    test "in components" do
      assigns = %{show: true, dont_show: false}

      code = """
      <Div :if={{ @show }}>
        Show
      </Div>
      <Div :if={{ @dont_show }}>
        Dont's show
      </Div>
      """

      assert render_live(code, assigns) == """
             <div>
               Show
             </div>
             """
    end

    test "in html tags" do
      assigns = %{show: true, dont_show: false}

      code = ~H"""
      <div :if={{ @show }}>
        Show
      </div>
      <div :if={{ @dont_show }}>
        Dont's show
      </div>
      """

      assert render_static(code) =~ """
             <div>
               Show
             </div>
             """
    end

    test "in void html elements" do
      assigns = %{show: true, dont_show: false}

      code = ~H"""
      <col class="show" :if={{ @show }}>
      <col class="dont_show" :if={{ @dont_show }}>
      """

      assert render_static(code) == """
             <col class="show">
             """
    end
  end

  describe ":show" do
    test "when true, do nothing" do
      assigns = %{show: true}

      code = ~H"""
      <col style="padding: 1px;" :show={{ @show }}>
      <col :show=true>
      """

      assert render_static(code) == """
             <col style="padding: 1px">
             <col>
             """
    end

    test "when false and style already exists, add `display: none`" do
      assigns = %{show: false}

      code = ~H"""
      <col style="padding: 1px;" :show={{ @show }}>
      """

      assert render_static(code) == """
             <col style="display: none; padding: 1px">
             """
    end

    test "when false and style does not exists, create style and add `display: none`" do
      assigns = %{show: false}

      code = ~H"""
      <col :show={{ @show }}>
      """

      assert render_static(code) == """
             <col style="display: none">
             """
    end
  end

  describe ":on-phx-*" do
    test "as an event map" do
      assigns = %{click: %{name: "ok", target: "#comp"}}

      code = ~H"""
      <button :on-phx-click={{ @click }}>OK</button>
      """

      assert render_static(code) =~ """
             <button phx-click="ok" phx-target="#comp">OK</button>
             """
    end

    test "as a string" do
      assigns = %{click: "ok"}

      code = ~H"""
      <button :on-phx-click={{ @click }}>OK</button>
      """

      assert render_static(code) =~ """
             <button phx-click="ok">OK</button>
             """
    end

    test "as a literal string" do
      assigns = %{}

      code = ~H"""
      <button :on-phx-click="ok">OK</button>
      """

      assert render_static(code) =~ """
             <button phx-click="ok">OK</button>
             """
    end

    test "as event name + target option" do
      assigns = %{}

      code = ~H"""
      <button :on-phx-click={{ "ok", target: "#comp" }}>OK</button>
      """

      assert render_static(code) =~ """
             <button phx-click="ok" phx-target="#comp">OK</button>
             """
    end

    test "do not translate invalid events" do
      assigns = %{}

      code = ~H"""
      <button :on-phx-invalid="ok">OK</button>
      """

      assert render_static(code) =~ """
             <button :on-phx-invalid="ok">OK</button>
             """
    end
  end
end

defmodule Surface.DirectivesSyncTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  import ComponentTestHelper

  alias Surface.DirectivesTest.{DivWithProps}, warn: false

  describe ":props on a component" do
    test "emits a warning with an unknown prop at runtime" do
      assigns = %{
        opts: %{
          unknown: "value",
          class: "text-xs",
          hidden: false,
          content: "dynamic props content"
        }
      }

      code = """
      <DivWithProps :props={{ @opts }} />
      """

      {:warn, message} = capture_warning(code, assigns)

      assert message =~ "Unknown property \"unknown\" for component <DivWithProps>"
    end
  end

  defp capture_warning(code, assigns) do
    output =
      capture_io(:standard_error, fn ->
        result = render_live(code, assigns)
        send(self(), {:result, result})
      end)

    result =
      receive do
        {:result, result} -> result
      end

    case output do
      "" ->
        {:ok, result}

      message ->
        {:warn, message}
    end
  end
end
