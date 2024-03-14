# frozen_string_literal: true

describe Nanoc::OrgMode::Filter, helper: true do
  it 'converts org-mode to HTML' do
    # Create item
    ctx.create_item('stuff', {}, '/foo.scss')
    ctx.create_rep(ctx.items['/foo.scss'], '/assets/foo.css')
    ctx.item = ctx.items['/foo.scss']

    filter = described_class.new(ctx.assigns)

    res = filter.run(<<~SOURCE)
      * My novel

      First paragraph.

      ** A second-level heading

      Here is the second paragraph.

      -----

      A third paragraph.
    SOURCE

    expect(res.strip).to match(%r{<p>First paragraph.</p>}m)
  end
end
