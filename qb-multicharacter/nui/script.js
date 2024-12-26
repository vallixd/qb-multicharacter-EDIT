var config = [];
var currentChar = null;
var nationalitys = [];
var playerCharacters = [];
var currentCidId = null;
var currentLocation = [];

$(document).ready(function() {
  function fetchData() {
    $.ajax({
      url: "https://countriesnow.space/api/v0.1/countries/",
      type: "GET",
      success: function(data) {
        const result = data.data;
        $.each(result, function(index, obj) {nationalitys.push(obj.country);});
      },
    });
  }
  fetchData();
  fetchCurrentChar = () => {
    if (playerCharacters.length > 0) {
      for (let i = 0; i < playerCharacters.length; i++) {
        if (playerCharacters[i].cid == currentCidId) {
          currentChar = playerCharacters[i];
        }
      }
    }
    return currentChar || null;
  };
  const loadLocale = (data) => {
    for (var key in data) {
      var value = data[key];
      if (key.includes("label")) {
        $(`[for='${key.match(/\['for=(.*?)'\]/)[1]}']`).text(value);
      } else {
        $(`.${key}`).html(value);
      }
    }
  };
  const openSPAWNUI = (data) => {
    $("body").slideDown(500);
    $(".character-slot-contain").slideUp(500);
    $(".spawn-ui-contain").slideDown(500);
  };
  $(document).on("click", "#spawn-play", function() {
    $.post("https://qb-multicharacter/SpawnPed", JSON.stringify({location: currentLocation.id, type: currentLocation.type}));
    $(".spawn-ui-contain").slideUp(500);
    $("body").slideUp(500);
  });
  setupLocations = (locations, isNew) => {
    var tLocation = null;
    $(".spawn-locations-list").empty();
    for (let i = 0; i < locations.length; i++) {
      const location = locations[i];
      if (tLocation == null) {
        tLocation = {
          location : i + 1,
          type : location.lastLoc ? "current" : "location"
        };
      }
      let spawnLocationHtml = `<div class="spawn-location" data-location="${i + 1}" data-type="${location.lastLoc ? "current" : "location"}"><div class="spawn-loc-informations"><h1>${location.title}</h1><p>${location.description}</p></div><img src="assets/house.png" alt=""/></div>`;
      if (location.lastLoc) {
        $(".spawn-locations-list").prepend(spawnLocationHtml);
      } else {
        $(".spawn-locations-list").append(spawnLocationHtml);
      }
    }
    if (isNew) {
      $(".spawn-ui-contain").slideDown(500);
      $("body").slideDown(500);
    }
  };
  $(document).on("click", ".spawn-location", function() {
    $(".spawn-location").each(function(k, v) {
      if ($(this).hasClass("active")) {
        $(this).removeClass("active");
      }
    });
    $(this).addClass("active");
    currentLocation.id = $(this).data("location");
    currentLocation.type = $(this).data("type");
    $.post("https://qb-multicharacter/setCam", JSON.stringify({location: currentLocation.id, type: currentLocation.type})); 
  });
  window.addEventListener("message", function(event) {
    let luaData = event.data;
    if (luaData.action == "showCHARNUI") {
      config = luaData.configData;
      loadCharMenu(luaData);
    } else if (luaData.action === "hideUI") {
      noDisplayForNUI();
    } else if (luaData.action == "openSPAWNUI") {
      openSPAWNUI(luaData.data);
    } else if (luaData.action == "loadLocale") {
      loadLocale(luaData.data);
    } else if (luaData.action == "setupLocations") {
      setupLocations(luaData.locations, luaData.isNew);
    }  
  });
  const loadCharMenu = (data) => {
    playerCharacters = data.playerCharacters;
    $("body").slideDown(500);
    $(".character-slot-contain").show();
    $(".character-slot-contain").empty();
    var maksCharCount = config.MaxCharacters;
    var lockedSlots = config.LockedSlots;
    for (let i = 0; i < maksCharCount; i++) {
      var status =
        config.LockTheSlots && lockedSlots.includes(i + 1)
          ? "none"
          : "available" || "available";
      var personImg = status == "available" ? "assets/plus.png" : "assets/lock.png";
      $(".character-slot-contain").append(`<div class="char-slot" data-status="${status}" data-cid="${i + 1}"><img src="${personImg}" alt="inside-img"></div>`);
    }
    if (playerCharacters.length > 0 && playerCharacters !== null) {
      for (let i = 0; i < playerCharacters.length; i++) {
        let charData = playerCharacters[i];
        $(`.char-slot[data-cid="${charData.cid}"]`).html(`<img src="assets/${i === 0 ? "availableperson" : "availableperson"}.png" alt=""></div>`);
        $(`.char-slot[data-cid="${charData.cid}"]`).attr("data-status", "created");
      }
    }
    currentCidId = 1;
    currentChar = fetchCurrentChar();
    const hasCharWithCidOne = playerCharacters.some((char) => char.cid === 1);
    if (hasCharWithCidOne) {
      $(".main-contain").show();
      $("#location").text(currentChar.charinfo.nationality);
      $("#birthdate").text(currentChar.charinfo.birthdate);
      $("#job").text(currentChar.job.label + ' - ' + currentChar.job.grade.name);
      $("#gang").text(currentChar.gang.label + ' - ' + currentChar.gang.grade.name);
      $("#cash").text(currentChar.money.cash);
      $("#bank").text(currentChar.money.bank);
      $("#name").text(currentChar.charinfo.firstname);
      $("#surname").text(currentChar.charinfo.lastname);
    }
    var firstSlot = $(`.char-slot[data-cid="1"]`);
    var firstSlotStatus = firstSlot.data("status");
    if (firstSlotStatus == "created") {
      firstSlot.addClass("active");
      $(`.char-slot[data-cid="1"]`).html(`<img src="assets/person.png" alt=""></div>`);
    } else if (firstSlotStatus == "available") {
      $(`.char-slot[data-cid="1"]`).addClass("active");
      $(`.char-slot[data-cid="1"]`).css("border", "1px dashed rgba(174, 227, 63, 1)");
      $(".create-char-contain").show();
    }
    $.post("https://qb-multicharacter/SetPedAction", JSON.stringify({data: currentChar})); 
  };
  $("#nation-context").click(function() {
    $(".context-menu").slideDown(500);
    $(".places-row").empty();
    for (var country in nationalitys) {
      var nationItem = `<div class="select-nation">${nationalitys[country]}</div>`;
      $(".places-row").append(nationItem);
    }
  });
  $("#search-inp").on("keyup", function() {
    var searchValue = $(this).val().toLowerCase();
    $(".select-nation").each(function() {
      var nationText = $(this).text().toLowerCase();
      if (nationText.indexOf(searchValue) > -1) {
        $(this).show();
      } else {
        $(this).hide();
      }
    });
  });
  $(document).on("click", ".char-slot", function() {
    var cid = Number($(this).data("cid"));
    currentCidId = cid;
    currentChar = fetchCurrentChar();
    var status = $(this).attr("data-status");
    $(".char-slot").each(function(k, v) {
      if ($(this).hasClass("active")) {
        if ($(this).data("status") == "created") {
          $(this).html(`<img src="assets/inputperson.png" alt=""></div>`); 
        } else if (status == "available") {
          $(this).css("border", "1px dashed rgba(249, 249, 249, 0.359)");
        }
        $(this).removeClass("active");
      }
    });
    $(this).addClass("active");
    if (status != "available" && status != "none") {
      $(this).html(`<img src="assets/person.png" alt=""></div>`);  
    }
    if (status == "available") {
      $(this).css("border", "1px dashed rgba(174, 227, 63, 1)");
    }
    if (status == "created") {
      $(".create-char-contain").slideUp(500, function() {
        $(".main-contain").slideDown(500);
        $("#location").text(currentChar.charinfo.nationality);
        $("#birthdate").text(currentChar.charinfo.birthdate);
        $("#job").text(currentChar.job.label + ' - ' + currentChar.job.grade.name);
        $("#gang").text(currentChar.gang.label + ' - ' + currentChar.gang.grade.name);
        $("#cash").text(currentChar.money.cash);
        $("#bank").text(currentChar.money.bank);
        $("#name").text(currentChar.charinfo.firstname);
        $("#surname").text(currentChar.charinfo.lastname);
      });
      $.post("https://qb-multicharacter/SetPedAction", JSON.stringify({data: currentChar}));
    } else if (status == "available") {
      $(".main-contain").slideUp(500, function() {
        $(".create-char-contain").slideDown(500);
      });
      $.post("https://qb-multicharacter/SetPedAction", JSON.stringify({data: null}));
    }
  });
  $(document).on("click", "#play-game", function() {
    $.post("https://qb-multicharacter/PlayGame", JSON.stringify({data: currentChar}),
      function(res) {
        if (res) {
          $("body").slideUp(300);
          $(".main-contain").slideUp(500);
          $(".character-slot-contain").slideUp(500);
        }
      }
    );
  });
  $(document).on("click", "#create-char", function() {
    var firstname = $("input[name='name']").val();
    var lastname = $("input[name='surname']").val();
    var birthdate = $("input[name='birthdate']").val();
    var height = $("input[name='height']").val();
    var nation = $("#nation-text").text();
    var gender = $(".gn[data-selected='true']").attr("data-type");
    var currentCid = currentCidId;
    if (firstname == "" || lastname == "") {
      return
    } else if (gender == null) {
      return;
    } else if (nation == "Nationality") {
      return;
    } else if (birthdate == "") {
      return;
    } else if (height == 0 || height > 200 || height == "") {
      return;
    }
    $(".create-char-contain").slideUp(500);
    $("body").slideUp(500);
    $.post("https://qb-multicharacter/CreateCharacter", JSON.stringify({firstname: firstname, lastname: lastname, birthdate: birthdate, height: height, nationality: nation, cid: currentCidId, gender: gender}));
    $("input[name='name']").val("");
    $("input[name='surname']").val("");
    $("input[name='birthdate']").val("");
    $("input[name='height']").val("");
    $("#nation-text").text("Nationality");
    $(".gn").each(function() {
      $(this).css("border", "none");
      $(this).attr("data-selected", "false");
    });
  });
  $(document).on("click", ".gn", function() {
    $(".gn").each(function() {
      $(this).css("border", "none");
      $(this).attr("data-selected", "false");
    });
    if ($(this).attr("data-type") == "female") {
      $(".gender").html("Kadın");
    } else {
      $(".gender").html("Erkek");
    }
    $(this).css("border", "1px solid #FFFFFF17");
    $(this).attr("data-selected", "true");
    $.post("https://qb-multicharacter/ChangeGender", JSON.stringify({gender: $(this).attr("data-type")}),
    );
  });
  $(document).on("click", ".select-nation", function() {
    $(".select-nation").each(function() {
      $(this).html($(this).text());
      $(this).data("selected", "false");
    });
    var currentNation = $(this).text();
    $(this).html(`${currentNation} <img src="assets/selected.png" alt="" style="left: 0; top: 0; position: relative;">`);
    $(this).data("selected", "true");
    $(".location").text(currentNation);
    $(".context-menu").slideUp(500);
  });
  $(document).keydown(function(e) {
    if (e.keyCode == 27) {
      if ($(".context-menu").is(":visible")) {
        $(".context-menu").slideUp(500);
      }
    }
  });
  const noDisplayForNUI = () => {};
});