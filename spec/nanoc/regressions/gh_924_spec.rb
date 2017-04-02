describe 'GH-924', site: true, stdio: true do
  before do
    File.write('nanoc.yaml', <<EOS)
text_extensions: [ 'xml', 'xsl' ]
EOS

    File.write('content/index.xml', '<root/>')

    File.write('layouts/default.xsl', <<EOS)
<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="xhtml">
<xsl:output encoding="UTF-8"
  doctype-public="-//W3C//DTD XHTML 1.1//EN"
  doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
  indent="yes" />
<xsl:strip-space elements="*" />

<xsl:include href='layouts/snippet.xsl' />

</xsl:stylesheet>
EOS

    File.write('layouts/snippet.xsl', <<EOS)
<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="xhtml">

<xsl:template match="/root">
  <html>
    <head>
      <title>Original Title</title>
    </head>
    <body>
      <p>Test Body</p>
    </body>
  </html>
</xsl:template>

</xsl:stylesheet>
EOS

    File.write('Rules', <<EOS)
compile '/index.xml' do
  layout '/default.xsl'
  write '/index.xhtml'
end

layout '/**/*.xsl', :xsl
EOS
  end

  before do
    Nanoc::CLI.run(%w[compile])
  end

  example do
    File.write('layouts/snippet.xsl', <<EOS)
<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="xhtml">

<xsl:template match="/root">
  <html>
    <head>
      <title>Changed Title</title>
    </head>
    <body>
      <p>Test Body</p>
    </body>
  </html>
</xsl:template>

</xsl:stylesheet>
EOS

    expect { Nanoc::CLI.run(%w[compile]) }
      .to change { File.read('output/index.xhtml') }
      .from(/<title>Original Title/)
      .to(/<title>Changed Title/)
  end
end
