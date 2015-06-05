#!/usr/bin/env ruby
# ©2015 Jean-Hugues Roy. GNU GPL v3.

require "csv"
require "nokogiri"
require "open-uri"

# baptême du fichier dans lequel on va mettre nos résultats
fichier = "saq.csv"

# création d'un array dans laquelle on place nos trois fichiers html créés à partir des résultats de recherche sur le site saq.com
urls = ["saq1.html", "saq2.html", "saq3.html"]

tout = []
n = 0

# boucle pour passer à travers chacun des fichiers html 
urls.each do |url|

	page = Nokogiri::HTML(open(url))

	page.css("div.wrapper-middle-rech").map { |contenu|

		(0..3).each do |i|
			produit = {} #création d'un hash pour chacun des produits rencontrés sur la page
			
			#je crée d'abord un numéro séquentiel pour chacun des produits rencontrés
			n += 1
			produit["No"] = n
			
			#il arrive que certains "emplacements" soient vides; on les saute avec la condition ci-dessous
			
			if contenu.css("p.nom a")[i] != nil
				nom = contenu.css("p.nom a")[i]["title"][40..-1]
				produit["Nom"] = nom #on extrait le nom du produit
				puts nom #affichage aux fins de vérification
				#dans certains noms de produits, il y a une année généralement placée à la fin; si c'est le cas, on va la chercher pour nous donner l'année du produit (millésime)
				if nom[-4..-3] == "20" || nom[-4..-3] == "19"
					annee = nom[-4..-1]
					produit["Année"] = annee
				elsif 
					produit["Année"] = "Inconnue"
				end
				puts annee
				
				#pour vérifier ultérieurement si notre extraction est conforme à la réalité, il est toujours bon de copier l'url de la page d'un produit, ainsi que l'url de l'image correspondant au produit
				urlProd = contenu.css("p.nom a")[i]["href"]
				produit["URL"] = urlProd
				puts urlProd
				image = contenu.css("div.img a")[i]["id"]
				image = image[image.index("_")+1..-1]
				puts image
				produit["URL-image"] = "http://s7d9.scene7.com/is/image/SAQ/" + image.to_s + "-1"
				
				#on va ensuite chercher le type de produit dont il est question ("vin rouge", "vodka", "bière", etc.)
				description = contenu.css("p.desc")[i].text.strip
				type = description[0..description.index("\r")-1]
				puts type
				produit["Type"] = type
				
				# certains produits ne sont pas des bouteilles d'alcool; on les exclut donc de notre extraction avec la condition ci-dessous
				if type != "Boîte cadeau" && type != "Sac cadeau" && type != "Alcootest" && type != "Article de bar" && type != "Pompe et bouchon" && type != "Sac réutilisable" && type != "Tire-bouchon" && type != "Bec verseur" && type != "Carte-cadeau"
					
					#si le produit est bel et bien de l'alcool, on extrait d'autres informations comme son pays d'origine et son volume
					pays = description[description.index("\n")..description.index(",")-1].gsub("\n", "").gsub("\r", "").gsub(/\u00A0/, "").strip
					produit["Pays"] = pays
					puts pays
					
					#le volume est une information très importante, puisqu'elle nous permet de comparer des produits réellement identiques
					volume = description[description.index(",")+2..description.index(",")+10].strip
					produit["Volume"] = volume
					puts volume
				else
					produit["Pays"] = "Inconnu"
					produit["Volume"] = "NSP"
				end
				
				#on va enfin chercher le prix du produit
				#il est d'abord sous forme d'une chaîne de caractères
				prix = contenu.css("td.price a")[i].text
				puts prix
				produit["Prix txt"] = prix
				
				#on traduit ensuite la chaînes de caractères en un nombre afin de faire des calculs plus tard
				prix2 = prix[0..-3].gsub(",",".").gsub(/\u00A0/, "").to_f
				puts prix2
				produit["Prix"] = prix2

			end
			puts n
			tout.push produit #chaque hash (1 produit) est placé dans un array contenant l'ensemble de notre extraction jusqu'à maintenant
		end

	}

end

puts tout #affichage aux fins de vérification

#quand tout est terminé, on produit un fichier CSV à partir du hash contenant l'ensemble de l'inventaire de la SAQ à ce moment-ci
CSV.open(fichier, "wb") do |csv|
  csv << tout.first.keys
  tout.each do |hash|
    csv << hash.values
  end
end
