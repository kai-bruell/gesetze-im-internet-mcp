  # Alle Paragraphen-Titel extrahieren:
  xmlstarlet sel -t -m "//norm/metadaten/enbez" -v "." -n estg.xml

  # Spezifischen § 70 finden:
  xmlstarlet sel -t -m "//norm[metadaten/enbez='§ 70']" -v "textdaten/text" estg.xml

  # Inhaltsverzeichnis extrahieren:
  xmlstarlet sel -t -m "//TOC/table//entry" -v "." -n estg.xml