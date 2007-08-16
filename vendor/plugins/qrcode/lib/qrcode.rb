module QRCode
  module QRCodeHelper
    def qrcode(url, size=2, id=nil)
      id ||= "qrcode_#{rand()}"
      output = %Q{<div class="qrcode" id="#{id}"></div><script type="text/javascript">
var qr = new QRCode(4, QRErrorCorrectLevel.H);
qr.addData('#{url}');
qr.make();
var text = "";
text += "<table style='border-width: 0px; border-style: none; border-color: #0000ff; border-collapse: collapse;'>";
for (var r = 0; r < qr.getModuleCount(); r++) {
    text += "<tr>";
    for (var c = 0; c < qr.getModuleCount(); c++) {
        if (qr.isDark(r, c) ) {
          text += "<td style='border-width: 0px; border-style: none; border-color: #0000ff; border-collapse: collapse; padding: 0; margin: 0; width: #{size}px; height: #{size}px; background-color: #000000;'/>";
        } else {
          text += "<td style='border-width: 0px; border-style: none; border-color: #0000ff; border-collapse: collapse; padding: 0; margin: 0; width: #{size}px; height: #{size}px; background-color: #ffffff;'/>";
        }
    }
    text += "</tr>";
}
text += "</table>";
Element.update($('#{id}'), text);
</script>
      }
    end
  end
end