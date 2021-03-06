locale = "en"
currentAlbum = "general"

$(document).ready -> init()

init = ->
	moveAmount = 10
	zoomAmount = 1.2;
	maxRotation = 60

	$(".menuButton").click ->
		menuSwitch($(@).attr "id")

	$("#thumbnailTable").on 'mouseenter', '.thumbnailCell', ->
		$("img", @).addClass("highlightedThumbnail")

	$("#thumbnailTable").on 'mouseleave', '.thumbnailCell', ->
		$("img", @).css {"transform": "", "-webkit-transform": "", "-ms-transform": ""}
		$("img", @).removeClass("clickedThumbnail")
		$("img", @).removeClass("highlightedThumbnail") if not $(@).hasClass "selectedThumbnail"

	$("#thumbnailTable").on 'mousedown', '.thumbnailCell', ->
		$(@).addClass("clickedThumbnail")

	$("#thumbnailTable").on 'mouseup', '.thumbnailCell', ->
		$(@).removeClass("clickedThumbnail")
		$(".imgThumbnail").removeClass("selectedThumbnail")
		$("img", @).addClass("selectedThumbnail")
		return if $("img", @).attr("id") is $("#mainImg").attr("data-filename")
		getPhoto($("img", @).attr "id")

	$("#thumbnailTable").on 'mousemove', '.thumbnailCell', (e) ->
		xPos = e.pageX - $(@).offset().left - $(@).width()/2
		yPos = e.pageY - $(@).offset().top - $(@).width()/2
		transform = "scale(" + zoomAmount + ", " + zoomAmount + ") perspective(600px) rotateY(" + xPos/100 * maxRotation + "deg) rotateX(" + yPos/100 * -maxRotation + "deg)"
		$("img", @).css {"transform": transform, "-webkit-transform": transform, "-ms-transform": transform}
	
	$("#aboutLabel").click ->
		open = $("#aboutPanel").hasClass("open")
		oldClass = (if open then "open" else "closed")
		newClass = (if open then "closed" else "open")
		$("#aboutPanel").switchClass(oldClass, newClass, {'duration': 1000, 'easing': 'easeOutQuart'});
		$(".dottedLine").css {"opacity": (if open then "1.0" else "0.0")}

	$(".socialButton").mouseenter ->
		$(@).prev().animate {opacity: "1.0", top: "-10px"}, 100

	$(".socialButton").mouseleave ->
		$(@).prev().animate {opacity: "0.0", top: "0px"}, 100

	$("#mainImg").load ->
		$("#mainImgShadow").width $("#mainImg").width()
		$("#mainImgShadow").height ($("#mainImg").height() * 0.5)

		$("#mainImgBacking").width $("#mainImg").width() - 2
		$("#mainImgBacking").height ($("#mainImg").height())

		$("#mainImg, #mainImgShadow").fadeTo 200, 1.0

	$("#rightArrow").click nextPhoto
	$("#leftArrow").click previousPhoto

	getLocale()
	menuSwitch(currentAlbum)

loadPhotoJSON = (photoJSON) ->
	log photoJSON
	return if photoJSON is null
	imgName = nameFromPath(photoJSON["path"]
	$("#mainImg, #mainImgShadow").fadeTo 200, 0.0, -> 
		$("#mainImg").attr "src", photoJSON["path"]
		$("#mainImg").attr "data-filename", imgName)
	$("#imgTitle").fadeTo 200, 0.0, -> 
		$("#imgTitle").html (if locale is "ja" then photoJSON["photo"]["japanese_title"] else photoJSON["photo"]["english_title"])
	$("#imgTitle").fadeTo 200, 1.0	
	photoNum = photoJSON["id"]
	$("#mainImgShadow").width $("#mainImg").width() - 4
	$("#mainImgShadow").height ($("#mainImg").height() * 0.6)
	$(".imgThumbnail").removeClass "selectedThumbnail"
	$("#" + imgName).addClass "selectedThumbnail"

menuSwitch = (menuName) ->
	$(".menuButton").each -> $(@).removeClass "selected_" + $(@).attr "id"
	selectedMenuObject = $("#" + menuName)
	selectedMenuObject.addClass "selected_" + menuName
	currentAlbum = menuName
	loadThumbnails(menuName)
	firstPhoto(currentAlbum)


loadThumbnails = (album) ->
	thumbnailFadeoutTime = 350
	thumbnailFadeoutInterval = 20

	delay = 0;
	$('.thumbnailCell').each -> 
	    $(@).delay $(@).index() * thumbnailFadeoutInterval
	    $(@).animate {opacity: 0}, thumbnailFadeoutTime

	$('.thumbnailRow').remove()

	imgNames = []

	$.post "home/getAlbum", {albumName:album}, (imgPaths) ->
		loadCounter = 0
		c = 0
		tr = $('<tr>', {class: 'thumbnailRow'})
		count = 0
		for imgPath in imgPaths
			img = $('<img>', {id: nameFromPath(imgPath), class: 'imgThumbnail', src: imgPath})

			img.load ->
				loadCounter += 1
				if loadCounter is imgPaths.length
					delay = 0;
					$('.imgThumbnail').each -> 
					    $(@).delay(delay)
					    $(@).animate {opacity: 0.4}, thumbnailFadeoutTime
					    delay += thumbnailFadeoutInterval

			td = $('<td>', {class: 'thumbnailCell'})
			td.append img

			tr.append td

			c += 1
			if c == 3
				c = 0
				$('#thumbnailTable').append tr
				tr = $('<tr>', {class: 'thumbnailRow'})

			if count + 1 is imgPaths.length
				$('#thumbnailTable').append tr

			count += 1

getLocale           = -> $.get "home/locale"   , {}, (data) -> locale = data
firstPhoto   	    = -> $.get "home/latest"   , {album:currentAlbum}, (data) -> loadPhotoJSON data
nextPhoto           = -> $.post "home/navigate", {currentPhoto:$("#mainImg").attr("data-filename"), album:currentAlbum, forwards: true}, (data) -> loadPhotoJSON data
previousPhoto       = -> $.post "home/navigate", {currentPhoto:$("#mainImg").attr("data-filename"), album:currentAlbum, forwards: false}, (data) -> loadPhotoJSON data
getPhoto = (id)       -> $.post "home/getPhoto", {photoID:id, album:currentAlbum}, (data) -> loadPhotoJSON data
nameFromPath = (path) -> path.match(/\d+/)
log = (s)		      -> console.log s


