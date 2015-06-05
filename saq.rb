#!/usr/bin/env ruby
# ©2015 Jean-Hugues Roy. GNU GPL v3.

require "csv"
require "nokogiri"
require "open-uri"

fichier = "saq.csv"

urls = ["saq1.html", "saq2.html", "saq3.html"]

tout = []
n = 0

urls.each do |url|

	page = Nokogiri::HTML(open(url))

	page.css("div.wrapper-middle-rech").map { |contenu|

		(0..3).each do |i|
			produit = {}
			n += 1
			produit["No"] = n
			if contenu.css("p.nom a")[i] != nil
				nom = contenu.css("p.nom a")[i]["title"][40..-1]
				produit["Nom"] = nom
				puts nom
				if nom[-4..-3] == "20" || nom[-4..-3] == "19"
					annee = nom[-4..-1]
					produit["Année"] = annee
				elsif 
					produit["Année"] = "Inconnue"
				end
				puts annee					
				urlProd = contenu.css("p.nom a")[i]["href"]
				produit["URL"] = urlProd
				puts urlProd
				image = contenu.css("div.img a")[i]["id"]
				image = image[image.index("_")+1..-1]
				puts image
				produit["URL-image"] = "http://s7d9.scene7.com/is/image/SAQ/" + image.to_s + "-1"
				description = contenu.css("p.desc")[i].text.strip
				type = description[0..description.index("\r")-1]
				puts type
				produit["Type"] = type
				if type != "Boîte cadeau" && type != "Sac cadeau" && type != "Alcootest" && type != "Article de bar" && type != "Pompe et bouchon" && type != "Sac réutilisable" && type != "Tire-bouchon" && type != "Bec verseur" && type != "Carte-cadeau"
					pays = description[description.index("\n")..description.index(",")-1].gsub("\n", "").gsub("\r", "").gsub(/\u00A0/, "").strip
					produit["Pays"] = pays
					puts pays
					volume = description[description.index(",")+2..description.index(",")+10].strip
					produit["Volume"] = volume
					puts volume
				else
					produit["Pays"] = "Inconnu"
					produit["Volume"] = "NSP"
				end
				prix = contenu.css("td.price a")[i].text
				puts prix
				produit["Prix txt"] = prix
				prix2 = prix[0..-3].gsub(",",".").gsub(/\u00A0/, "").to_f
				puts prix2
				produit["Prix"] = prix2

			end
			puts n
			tout.push produit
		end

	}

end

puts tout

# 	# puts tout

CSV.open(fichier, "wb") do |csv|
  csv << tout.first.keys
  tout.each do |hash|
    csv << hash.values
  end
end
