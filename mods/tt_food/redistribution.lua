local function add_eatable(name, hp)
	local item = minetest.registered_items[name]

	if item and item.groups.eatable == nil then
		local groups = table.copy(item.groups) or {}
		groups.eatable = hp
		minetest.override_item(name, {groups = groups})
	end
end



-- animalworld

add_eatable("animalworld:anteggs_raw", 2)
add_eatable("animalworld:anteggs_cooked", 6)
add_eatable("animalworld:whalemeat_raw", 4)
add_eatable("animalworld:whalemeat_cooked", 8)
add_eatable("animalworld:pork_raw", 4)
add_eatable("animalworld:pork_cooked", 8)
add_eatable("animalworld:rawfish", 3)
add_eatable("animalworld:cookedfish", 5)
add_eatable("animalworld:roastroach", 2)
add_eatable("animalworld:rabbit_raw", 3)
add_eatable("animalworld:rabbit_cooked", 5)
add_eatable("animalworld:locust_roasted", 8)
add_eatable("animalworld:chicken_egg_fried", 2)
add_eatable("animalworld:chicken_raw", 2)
add_eatable("animalworld:chicken_cooked", 6)
add_eatable("animalworld:bugice", 2)
add_eatable("animalworld:rat_cooked", 3)
add_eatable("animalworld:escargots", 2)
add_eatable("animalworld:raw_athropod", 3)
add_eatable("animalworld:cooked_athropod", 5)
add_eatable("animalworld:rawmollusk", 3)
add_eatable("animalworld:cookedmollusk", 5)
add_eatable("animalworld:termitequeen", 2)
add_eatable("animalworld:bucket_milk", 8)
add_eatable("animalworld:glass_milk", 2)
add_eatable("animalworld:butter", 1)
add_eatable("animalworld:cheese", 4)



-- aqua_farming

add_eatable("aqua_farming:alga_item", 1)
add_eatable("aqua_farming:sea_anemone_item", 5)
add_eatable("aqua_farming:sea_cucumber_item", 4)
add_eatable("aqua_farming:sea_strawberry_cake_piece", 3)
add_eatable("aqua_farming:sea_strawberry_item", 3)



-- goblins

add_eatable("goblins:mushroom_goblin", 2)
add_eatable("goblins:mushroom_goblin1", 2)
add_eatable("goblins:mushroom_goblin2", 2)
add_eatable("goblins:mushroom_goblin3", 2)
add_eatable("goblins:mushroom_goblin4", 2)



-- hardcore_farming

add_eatable("hardcore_farming:locust_roasted", 8)
add_eatable("hardcore_farming:rat_cooked", 3)



-- livingcaves

add_eatable("livingcaves:healingsoup", 8)
add_eatable("livingcaves:mushroom_edible", 5)



-- livingcavesmobs

add_eatable("livingcavesmobs:cocoon", 2)
add_eatable("livingcavesmobs:mothegg", 2)



-- livingdesert

add_eatable("livingdesert:date_palm_fruits", 6)
add_eatable("livingdesert:figcactus_fruit", 6)



-- livingfloatlands

add_eatable("livingfloatlands:ornithischiaraw", 3)
add_eatable("livingfloatlands:ornithischiacooked", 5)
add_eatable("livingfloatlands:theropodraw", 3)
add_eatable("livingfloatlands:theropodcooked", 5)
add_eatable("livingfloatlands:coldsteppe_bulbous_chervil_root", 2)
add_eatable("livingfloatlands:roasted_pine_nuts", 5)
add_eatable("livingfloatlands:coldsteppe_pine_pinecone", 2)
add_eatable("livingfloatlands:coldsteppe_pine2_pinecone", 2)
add_eatable("livingfloatlands:coldsteppe_pine3_pinecone", 2)
add_eatable("livingfloatlands:largemammalraw", 3)
add_eatable("livingfloatlands:largemammalcooked", 5)
add_eatable("livingfloatlands:giantforest_oaknut_cracked", 5)
add_eatable("livingfloatlands:giantforest_oaknut", 2)
add_eatable("livingfloatlands:sauropodraw", 3)
add_eatable("livingfloatlands:sauropodcooked", 5)
add_eatable("livingfloatlands:paleojungle_clubmoss_fruit", 5)



-- marinara

add_eatable("marinara:mussels_cooked", 8)
add_eatable("marinara:raw_oisters", 6)



-- marinaramobs

add_eatable("marinaramobs:octopus_raw", 3)
add_eatable("marinaramobs:octopus_cooked", 5)
add_eatable("marinaramobs:raw_exotic_fish", 3)
add_eatable("marinaramobs:cooked_exotic_fish", 5)
add_eatable("marinaramobs:seaurchin_cooked", 8)



-- nativevillages

add_eatable("nativevillages:catfish_raw", 4)
add_eatable("nativevillages:catfish_cooked", 8)
add_eatable("nativevillages:bucket_milk", 8)
add_eatable("nativevillages:glass_milk", 2)
add_eatable("nativevillages:butter", 1)
add_eatable("nativevillages:cheese", 4)
add_eatable("nativevillages:driedhumanmeat", 2)
add_eatable("nativevillages:chicken_egg_fried", 2)
add_eatable("nativevillages:chicken_raw", 2)
add_eatable("nativevillages:chicken_cooked", 6)



-- naturalbiomes

add_eatable("naturalbiomes:cowberry", 2)
add_eatable("naturalbiomes:alpine_mushroom", 1)
add_eatable("naturalbiomes:blackberry", 2)
add_eatable("naturalbiomes:wildrose", 2)
add_eatable("naturalbiomes:hazelnut", 2)
add_eatable("naturalbiomes:hazelnut_cracked", 5)
add_eatable("naturalbiomes:olives", 6)
add_eatable("naturalbiomes:banana_bunch", 6)
add_eatable("naturalbiomes:banana", 2)
add_eatable("naturalbiomes:coconut_slice", 2)
add_eatable("naturalbiomes:coconut", 6)



-- people

add_eatable("people:dogfood", 2)
add_eatable("people:dogfood_cooked", 6)
add_eatable("people:mutton_raw", 2)
add_eatable("people:mutton_cooked", 6)
add_eatable("people:bandage", 2)



-- variety

add_eatable("variety:bamboo_cooked", 2)



-- xnether

add_eatable("xnether:fruit", -3)



-- xocean

add_eatable("xocean:kelp", 1)
add_eatable("xocean:sushi", 6)
add_eatable("xocean:fish_edible", 3)
