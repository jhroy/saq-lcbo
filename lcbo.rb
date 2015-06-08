#!/usr/bin/env ruby
# ©2015 Jean-Hugues Roy. GNU GPL v3.

require "csv"
require "json"
require "open-uri"
require "i18n" #gem d'internationalisation très utile, car l'API avait du mal avec certains caractères français

I18n.enforce_available_locales = false

cleAPI = <votre clé ici>

saq = CSV.read("saq.csv", headers:true)
puts saq.size

(0..12).each do |x| #boucle qui découpe notre fichier saq.csv en 13 morceaux pour faciliter le traitement, car les erreurs peuvent être nombreuses et il peut être embêtant de tout reprendre depuis le début

	puts x

	tout = []
	fichier = "lcbo-#{x}.csv" #à chaque boucle, on va pondre un fichier CSV distinct

	((x*1000)..(x*1000)+999).each do |n| #à chaque boucle, on crée une sous-boucle pour traiter successivement tous les blocs de 1000 produits SAQ

		if n < saq.size #arrivés à 12129, on arrête, car c'est le nombre total de produits SAQ qu'on a extraits

			produit = saq[n] #les caractéristiques de chaque produit SAQ sont placés dans un array

			q = produit[1] #la variable q prend le nom du produit SAQ; c'est ce nom qu'on va soumettre à l'API de la LCBO

			if q != nil || q != '""' #si le champ du nom n'est pas vide, on procède

				if q[-4..-3] == "20" || q[-4..-3] == "19" #on extrait l'année du nom du produit, afin de ratisser le plus large possible dans l'API de la LCBO
					q = q[0..-6]
				end

				#on effectue diverses opérations de nettoyage et de formatage du nom du produit avant de le soumetre à l'API
				q = q.gsub(" ", "+").gsub("-", "+").gsub(".", "+").gsub("&", "+").gsub(",", "").gsub("%","").gsub("`", "'").gsub(/\n/, "+").gsub("\"","")
				q = q.gsub(/[\+]+/, "+")
				q = I18n.transliterate(q)

				#voilà, on envoie notre requête à l'API; j'ai limité le nombre de résultats à 25, ce qui est un peu plus que la valeur par défaut de l'API (qui est de 20), afin de ratisser un tout petit peu plus large
				requete = "http://lcboapi.com/products?per_page=25&q=#{q}&access_key=#{cleAPI}"
				puts "Requête ##{n}"

				#on traite («parse») le JSON qui nous est retourné par l'API 
				res = open(requete)
				data = JSON.parse(res.read)

				pager = data["pager"]
				nbResultats = pager["total_record_count"] #on extrait le nombre de résultats que l'API nous a retourné pour le produit SAQ demandé
				puts "=> #{nbResultats} résultats pour #{q}" #affichage aux fins de vérification

				if nbResultats > 0 && nbResultats < 26 #si on a des résultats (car souvent, l'API n'en retournait aucun), on extrait de l'info dans chacun de ces résultats

					resultats = data["result"]

					(0..nbResultats-1).each do |i| #boucle en fonction du nombre de résultats obtenu

						if resultats[i]["name"] != nil
							puts "#{resultats[i]["name"]} (#{(i+1)})" #autre affichage pour vérifier

							match = {} #on crée un hash pour chaque résultat retourné par l'API

							match["Nom SAQ"] = produit[1] #on y met d'abord le nom du produit SAQ recherché
							match["Nom LCBO"] = resultats[i]["name"] #ensuite: le nom du produit LCBO correspondant au résultat
							match["Prix SAQ"] = produit[9] #le prix demandé par la SAQ
							prixLCBO = resultats[i]["regular_price_in_cents"].to_f
							prixLCBO = (prixLCBO/100)
							match["Prix LCBO"] = prixLCBO
							match["Différence"] = (match["Prix SAQ"].to_f - match["Prix LCBO"].to_f).round(2) #on calcule tout de suite la différence de prix, même si on n'est pas certain que ce sont deux produits comparables
							match["Diff. %"] = ((match["Différence"].to_f/match["Prix LCBO"].to_f)*100).round(2) #on calcule aussi immédiatement le pourcentage de la différence par rapport au prix LCBO

							#on extrait d'autres infos du JSON
							match["Volume SAQ"] = produit[7]
							match["Volume LCBO"] = resultats[i]["volume_in_milliliters"]
							match["Type SAQ"] = produit[5]
							match["Type LCBO"] = resultats[i]["secondary_category"]
							match["image SAQ"] = produit[4]
							match["image LCBO"] = resultats[i]["image_url"]

							tout.push match #on place notre hash («match») dans un array appelé «tout»

							puts match #affichage aux fins de vérification
						end

					end
				end

			end
		end

	end

	#à la fin de chaque boucle (après avoir vérifié 1000 produits SAQ), on confine nos résultats dans un CSV

	CSV.open(fichier, "wb") do |csv|
	  csv << tout.first.keys
	  tout.each do |hash|
	    csv << hash.values
	  end
	end
end
