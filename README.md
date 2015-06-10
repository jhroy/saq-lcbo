# saq-lcbo
Projet de comparaison entre les prix de la SAQ et de la LCBO. :wine_glass:

- **saq.rb** : script pour extraire l'inventaire de la SAQ
- **lcbo.rb** : script pour comparer l'inventaire de la SAQ à celui de la LCBO en utilisant l'[API LCBO](https://lcboapi.com/) mis au point par [Carsten Nielsen](http://heycarsten.com/).
- **match.csv** : fichier brut des 755 produits offerts à la fois à la SAQ et à la LCBO en mars 2015. Il y en peut-être un nombre différent si vous répétez cet exercice aujourd'hui.
- **lcbo-inventaire** : inventaire complet de la LCBO (ATTENTION: une version antérieure n'avait pas converti les cents en dollars, ce qui multipliait par 100 les valeurs affichées... Doh!)
