let backpackMeta = ['backpack', 'backpack1', 'backpack2', 'backpack3'];
let phoneMeta = ['phone', 'black_phone', 'yellow_phone', 'red_phone', 'green_phone'];
let clothingItem = ["tshirt_1", "torso_1", "arms", "pants_1", "shoes_1", "mask_1", "bproof_1", "chain_1", "helmet_1", "glasses_1", "watches_1", "bracelets_1", "bags_1"];

export function sendInfoData(item) {
    let iteminfo = item.info || {};
    let returnString = "";

    if (item.name == "id_card") {
        let man = iteminfo.gender === 1 ? "Woman" : "Man";
        let infoData = [
            { label: "Firstname", value: iteminfo.firstname || "Unknown" },
            { label: "Lastname", value: iteminfo.lastname || "Unknown" },
            { label: "Birthdate", value: iteminfo.birthdate || "Unknown" },
            { label: "Nationality", value: iteminfo.nationality || "Unknown" },
            { label: "Gender", value: man },
            { label: "Citizen", value: iteminfo.citizenid || "Unknown" }
        ];
        returnString = infoData;
    } else if (item.name.match("driver_license")) {
        let infoData = [
            { label: "Firstname", value: iteminfo.firstname || "Unknown" },
            { label: "Lastname", value: iteminfo.lastname || "Unknown" },
            { label: "Birthdate", value: iteminfo.birthdate || "Unknown" },
            { label: "Licenses", value: iteminfo.type || "Unknown" },
        ];
        returnString = infoData;
    } else if (phoneMeta.includes(item.name)) {
        let charinfo = iteminfo.charinfo || {};
        let infoData = [
            { label: "Firstname", value: charinfo.firstname || "Unknown" },
            { label: "Lastname", value: charinfo.lastname || "Unknown" },
            { label: "Number", value: charinfo.phoneNumber || "Unknown" }
        ];
        returnString = infoData;
    } else if (item.name.match("lawyerpass")) {
        let infoData = [
            { label: "ID", value: iteminfo.id || "Unknown" },
            { label: "Firstname", value: iteminfo.firstname || "Unknown" },
            { label: "Lastname", value: iteminfo.lastname || "Unknown" },
            { label: "Citizen", value: iteminfo.citizenid || "Unknown" }
        ];
        returnString = infoData;
    } else if (item.name.match("harness")) {
        let infoData = [
            { label: "USES : ", value: iteminfo.uses || "Unknown" },
        ];
        returnString = infoData;
    } else if (item.name.match("weapon")) {
        let infoData = [
            { label: "Serial", value: iteminfo.series || "Unknown" },
            { label: "Ammo", value: iteminfo.ammo || "Unknown" },
            { label: 'Quality', value: iteminfo.quality ? iteminfo.quality.toFixed(1) : 0 },
            { label: 'Repair Count', value: iteminfo.repair && iteminfo.maxrepair ? iteminfo.repair + ' / ' + iteminfo.maxrepair : "Unknown" },
        ];
        returnString = infoData;
    } else if (backpackMeta.includes(item.name)) {
        let infoData = [
            { label: "Info", value: iteminfo.series || "Unknown" },
            { label: "Slot", value: iteminfo.slot || "Unknown" },
            { label: "Weight", value: iteminfo.weight || "Unknown" },
        ];
        returnString = infoData;
    } else if (clothingItem.includes(item.name)) {
        let infoData = [
            { label: "Clothing ID", value: iteminfo.skin || "Unknown" },
            { label: "Texture", value: iteminfo.texture || "Unknown" },
        ];
        returnString = infoData;
    }
    return returnString;
}
