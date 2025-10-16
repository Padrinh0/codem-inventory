
var audioPlayer = null;
var soundFx = true

import { sendInfoData } from "../../config/metadata.js";
import inlinesvg from './util/inlinesvg.js';
const store = Vuex.createStore({
    components: {
        inlinesvg: inlinesvg,

    },
    state: {


    },
    getters: {},
    mutations: {

    },
    actions: {

    }
});


$(document).ready(function () {
    var checkOnlineStatus = true;
    var checkInterval = 5000;
    var timeout = 1500;
    var timer; // timer değişkenini burada tanımlayın

    function checkOnline() {
        if (!checkOnlineStatus) {
            return;
        }

        $.ajax({
            url: "https://jsonplaceholder.typicode.com/posts",
            timeout: timeout,
            success: function () {
                $.post("https://codem-inventory/onlinecheck", JSON.stringify({}));
            },
            error: function (xhr, textStatus) {
                $.post("https://codem-inventory/offlinecheck", JSON.stringify({}));
            },
            complete: function () {
                if (checkOnlineStatus) { // checkOnlineStatus kontrol edin
                    timer = setTimeout(checkOnline, checkInterval);
                }
            }
        });
    }

    checkOnline();

    $(window).on('beforeunload', function () {
        checkOnlineStatus = false;
        if (timer) { // timer'ın tanımlı olup olmadığını kontrol edin
            clearTimeout(timer);
        }
    });
});

const app = Vue.createApp({
    components: {
        inlinesvg: inlinesvg,
    },
    data: () => ({
        status: {
            health: 0,
            armor: 0,
            hunger: 0,
            thirst: 0,
            stamina: 0,
            cash: 0,
            bank: 0,
        },
        currentThema: 'orange',
        themaColor: [
            { name: 'orange', color: '#FF8833 ' },
            { name: 'green', color: '#43FF88' },
            { name: 'purple', color: '#FF43DC' },
            { name: 'red', color: '#FF4343' },
            { name: 'blue', color: '#43CCFF' },
            { name: 'white', color: '#ffffff' }
        ],
        clothesIconData: [
            { name: "hat", icon: "haticon", itemname: "helmet_1" },
            { name: 'mask', icon: 'maskicon', itemname: 'mask_1' },
            { name: 'glasses', icon: 'glassesicon', itemname: "glasses_1" },
            { name: 'tshirt', icon: 'tshirticon', itemname: "tshirt_1" },
            { name: 'jacket', icon: 'jacketicon', itemname: 'torso_1' },
            { name: 'armor', icon: 'armoricon', itemname: 'bproof_1' },
            { name: 'bagoff', icon: 'bagicon', itemname: 'bags_1' },
            { name: 'gloves', icon: 'glovesicon', itemname: 'arms' },
            { name: 'bracelet', icon: 'braceleticon', itemname: 'bracelets_1' },
            { name: 'chain', icon: 'chainicon', itemname: 'chain_1' },
            { name: 'watch', icon: 'watchicon', itemname: 'watches_1' },
            // { name: 'pant', icon: 'panticon' },
            // { name: 'shoes', icon: 'shoesicon' },
            { name: 'pant', icon: 'panticon', itemname: 'pants_1' },
            { name: 'shoes', icon: 'shoesicon', itemname: 'shoes_1' },
        ],
        contextMenuData: [
        ],
        adjustmentsData: [
            // { name: 'autosortitems', label: 'Auto Sort Items', value: false },
            // { name: 'lights', label: 'Lights', value: false }
        ],
        showContextMenu: false,
        contextMenuValue: 'main',
        menuPosition: { x: 0, y: 0 },
        contextmenuIndex: -1,
        layout: 1,
        openSettingsPage: false,
        PlayerInventory: {

        },
        Category: [
        ],
        filterCategoryName: 'all',
        searchInventoryItem: "",
        maxSlot: 35,
        maxWeight: 100000,
        PlayerInventoryWeight: 0,
        show: false,
        rightinventory: 'ground',
        rightInventoryData: false,
        rightInventoryWeight: 0,
        progressBar: {},
        notifications: [],
        hotBar: false,
        contextMenuItem: false,
        hoverMenuItem: false,
        hoverMenuShow: false,
        infoonbottomvalue: false,
        infoonbottomItem: false,
        bottomMenu: [],
        splitAmount: 1,
        closestPlayers: [],
        playerInfo: {
            name: '',
            id: '',
            job: '',
            jobgrade: '',
        },
        shopAmount: '',
        lights: 'layout2notlight',
        configClothing: false,
        cashitem: false,
        heightbar: false,
        weighticon: 'whitebag',
        serverlogo: false,
        stashContext: false,
        locales: [],
        layout2Clothes: false,
        paymentMethod: 'cash',
        ClothingInventory: [],
        showProp: false,
        groundslot: 0,
        showInfoValue: false,
        craftingPage: false,
        craftingItems: [

        ],
        craftingItem: false,
        countdown: 0,
        startCraft: false,
        progressWidth: 0,
        waitingCraftItem: false,
        allowedCraft: false
    }),
    methods: {
        OpenCraftPage() {
            this.craftingPage = true
            this.craftingItem = false
        },
        closeCrafting() {
            this.craftingPage = false
            this.craftingItem = false
        },
        GetInventoryCraftCount(reuiredItem) {
            let myInventory = Object.values(this.PlayerInventory);
            const item = myInventory.find(item => item.name === reuiredItem);
            return item ? item.amount : 0;
        },
        finishCraftItem() {
            if (this.countdown > 0) {
                this.notification('Crafting is not finished yet')
                return
            }
            this.countdown = 0;
            this.startCraft = false;
            postNUI('FinishCraftItem', this.waitingCraftItem)
            this.waitingCraftItem = false;
        },
        async craftItem() {
            let result = await postNUI('CraftItem', this.craftingItem)
            if (result) {
                this.countdown = 0;
                this.waitingCraftItem = this.craftingItem;
                this.startCountdown(this.craftingItem.time);
                this.startCraft = true;
                this.notification(this.locales['CRAFTINGSTARTED'])
            } else {
                this.notification(this.locales['YOUDONTHAVEITEMS'])
            }
        },
        startCountdown(time) {
            this.countdown = time;
            this.updateCountdown();
        },
        updateCountdown() {
            if (this.countdown > 0) {
                setTimeout(() => {
                    this.countdown--;
                    this.progressWidth = ((this.craftingItem.time - this.countdown) / this.craftingItem.time) * 100;
                    this.updateCountdown();
                }, 1000);
            } else {
                postNUI('craftnotification', this.locales['CRAFTFINISHED'])
            }


        },
        formatTime(seconds) {
            const minutes = Math.floor(seconds / 60);
            const remainingSeconds = seconds % 60;
            return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
        },
        selectedCraftingItem(value) {
            this.craftingItem = value
        },
        sortItem() {
            postNUI('SortItem')
        },
        sortItemStash() {
            if (!this.rightInventoryData.stashId) {
                return
            }
            postNUI('SortItemStash', this.rightInventoryData.stashId)
        },
        takeoffclothes(val) {
            if (val) {
                postNUI('TakeOffClothes', val)
            }
        },
        changePaymentMethod(val) {
            this.paymentMethod = val
        },
        changeLayout2() {
            this.layout2Clothes = !this.layout2Clothes
            if (!this.layout2Clothes) {
                postNUI('DisablePedScreen')
            } else {
                postNUI('EnablePedScreen')
            }
            setTimeout(() => {
                this.inventoryDrag()
                this.mainInventoryDrop()
            }, 50)
        },
        SetClothes(value) {
            if (value) {
                postNUI('UpdateClothes', value)
            }
        },
        ClothingMenu() {
            if (!this.openSettingsPage) {
                return true
            }
        },
        changeLayout(val) {
            if (this.layout == val) return;
            this.layout = val
            localStorage.setItem('layout', val);
            if (this.layout == 2) {
                postNUI('DisablePedScreen')
                setTimeout(() => {
                    this.heightbar = false
                    this.layout2weight()
                }, 1000)

            } else {
                postNUI('EnablePedScreen')

                setTimeout(() => {
                    this.setupHudProgressbar('health', '#FF4848', '#ff48482d')
                    this.setupHudProgressbar('armor', '#4870FF', '#4870FF2d')
                    this.setupHudProgressbar('hunger', '#FFA048', '#FFA0482d')
                    this.setupHudProgressbar('thirst', '#48FFF4', '#48FFF42d')
                    this.setupHudProgressbar('stamina', '#C4FF48', '#C4FF482d')

                    if (!this.cashitem) {
                        this.setupHudProgressbar('cash', '#C4FF48', '#C4FF482d')
                        this.progressBar.cash.animate(1.0)
                    }
                    this.setupHudProgressbar('bank', '#ffffff', '#ffffff37')
                    this.setupHudProgressbar('weight', '#FF8934', '#FF89342d')

                    this.progressBar.bank.animate(1.0)
                    this.progressBar.health ? this.animate(this.status.health / 100) : this.progressBar.health.animate(0);
                    this.progressBar.armor.animate(this.status.armor / 100);
                    this.status.hunger ? this.progressBar.hunger.animate(this.status.hunger / 100) : this.progressBar.hunger.animate(0);
                    this.status.thirst ? this.progressBar.thirst.animate(this.status.thirst / 100) : this.progressBar.thirst.animate(0);
                    this.progressBar.stamina.animate(this.status.stamina / 100);
                    this.progressBar.weight.animate(this.PlayerInventoryWeight / this.maxWeight);
                }, 1000)



            }
            setTimeout(() => {
                this.inventoryDrag()
                this.mainInventoryDrop()
            }, 50)
        },
        GetWeaponAttachIcon(item) {
            if (item.info) {
                const hasAttachments = Array.isArray(item.info.attachments) && item.info.attachments.length > 0;
                if (hasAttachments) {
                    return true
                }
            }
        },
        checkInputMin() {
            if (this.shopAmount.length > 0) {
                this.shopAmount = this.shopAmount.replace(/[^0-9]/g, "");
            }
        },
        itemSplit(item, amount) {
            if (item.amount <= amount) {
                return;
            }
            if (this.stashContext == 'stash') {
                if (this.rightInventoryData.stashId == null) {
                    this.notification(this.locales['UNKOWNSTASHNAME'])
                    return;
                }
                postNUI('SplitItemStash', { item: item, amount: amount, stashId: this.rightInventoryData.stashId, maxslot: this.rightInventoryData.slot, weight: this.rightInventoryData.maxweight })
            } if (this.stashContext == 'glovebox') {
                if (this.rightInventoryData.plate == null) {
                    this.notification(this.locales['NOTFOUNDPLATE']);
                    return;
                }
                postNUI('SplitItemGloveBox', { item: item, amount: amount, plate: this.rightInventoryData.plate, maxslot: this.rightInventoryData.slot, weight: this.rightInventoryData.maxweight })
            } if (this.stashContext == 'trunk') {
                if (this.rightInventoryData.plate == null) {
                    this.notification(this.locales['NOTFOUNDPLATE']);
                    return;
                }
                postNUI('SplitItemTrunk', { item: item, amount: amount, plate: this.rightInventoryData.plate, maxslot: this.rightInventoryData.slot, weight: this.rightInventoryData.maxweight })
            } else {
                postNUI('SplitItem', { item: item, amount: amount })
            }
            this.splitAmount = 1

        },
        changeAdjustment(name, value) {
            value = !value
            const adjustment = this.adjustmentsData.find(item => item.name === name);
            if (adjustment) {
                adjustment.value = value;
                localStorage.setItem(name, value);
                if (name == 'hoverinfo') {
                    this.hoverMenuShow = value
                    this.notification(this.locales['HOVERINFO'] + (value ? this.locales['ENABLED'] : this.locales['DISABLED']));

                }
                if (name == 'infoonbottom') {
                    this.infoonbottomvalue = value
                    this.notification(this.locales['INFOONBOTTOM'] + (value ? this.locales['ENABLED'] : this.locales['DISABLED']));
                }
                if (name == 'lights') {
                    this.notification('Lights ' + (value ? 'Enabled' : 'Disabled'))
                    if (this.layout == 2) {
                        this.lights = value ? 'layout2light' : 'layout2notlight'
                    } else {
                        this.lights = value ? 'layout1light' : 'layout1notlight'
                    }

                }
                if (name == 'soundfx') {
                    soundFx = value
                    this.notification(this.locales['SOUND'] + (value ? this.locales['ENABLED'] : this.locales['DISABLED']));
                }
            }
        },
        changeThema(val) {
            if (this.currentThema == val) return;

            this.currentThema = val
            localStorage.setItem('thema', val);
        },
        bottommenu(val) {
            const timeout = 4000;
            let id = Date.now();
            let newNotification = {
                id: id,
                value: val,
                timeout: setTimeout(() => {
                    this.bottomMenu = this.bottomMenu.filter(notification => notification.id !== id);
                }, timeout)
            };
            this.bottomMenu.push(newNotification);


        },
        notification(text) {
            const timeout = 6000;
            let id = Date.now();
            if (this.notifications.some(notification => notification.text === text)) {
                return;
            }
            let newNotification = {
                id: id,
                text: text,
                timeout: setTimeout(() => {
                    this.notifications = this.notifications.filter(notification => notification.id !== id);
                }, timeout)
            };
            this.notifications.push(newNotification);
        },
        setupHudProgressbar(type, color, trailColor) {
            if (this.layout == 2) return;
            this.progressBar[type] = new ProgressBar.Circle('#' + type, {
                strokeWidth: 10,
                easing: 'easeInOut',
                duration: 1400,
                color: color,
                trailColor: trailColor,
                trailWidth: 10,
                svgStyle: null
            });
        },
        filterItem(val) {
            this.filterCategoryName = val;
            this.contextMenuItem = false;
        },
        openSettingsModal(val) {
            this.openSettingsPage = val;
            this.contextMenuItem = false;
        },
        closeContextMenu() {
            this.contextMenuValue = 'main'
            this.showContextMenu = false;
            this.contextMenuItem = false;
        },
        handleContextMenuClick(val) {
            if (val.name == 'split') {
                this.contextMenuValue = 'split'
            }
            if (val.name == 'give') {
                this.GetClosestPlayers()
            }
            if (val.name == 'use') {
                postNUI('UseItem', this.contextMenuItem)
                this.showContextMenu = false;
            }
            if (val.name == 'info') {
                if (this.contextMenuItem && this.contextMenuItem.info) {
                    this.GetInfoData()
                } else {
                    this.notification('No Info')
                }
            }
            if (val.name == 'drop') {
                postNUI('swapMainInventoryToGround', { oldSlot: this.contextMenuItem.slot })
                this.showContextMenu = false;
            }
            if (val.name == 'attachment') {

                this.contextMenuValue = 'attachment'
            }
            if (val.name == 'tint') {
                postNUI('tintItem', this.contextMenuItem)
                this.showContextMenu = false;
            }
        },
        async GetClosestPlayers() {
            let result = await postNUI('GetClosestPlayers')
            this.closestPlayers = result
            this.contextMenuValue = 'give'
        },
        removeAttachment(item, attachment) {
            if (item == null) {
                return;
            }
            if (attachment == null) {
                this.notification(this.locales['NOATTACHMENT']);
                return;
            }
            postNUI('removeAttachment', { item: item, attachment: attachment })
            this.showContextMenu = false;
            this.contextMenuItem = false;
        },
        GiveItemToNearbyPlayers(player, item) {
            if (player == null) {
                this.notification(this.locales['NOTFOUNDPLAYER']);
                return;
            }
            if (item == null) {
                return;
            }
            postNUI('GiveItemToPlayer', { player: player, item: item })
            this.showContextMenu = false;
            this.contextMenuItem = false;
        },
        GetInfoData() {
            this.contextMenuValue = 'info'
            return sendInfoData(this.contextMenuItem)
        },
        GetInfoDataItem(item) {
            if (item == null) {
                return;
            }
            if (sendInfoData(item).length == 0) {
                return this.showInfoValue = false;
            } else {
                return sendInfoData(item)
            }

        },
        GetSlotNumberContainer(index) {
            if (index < 6) {
                return true
            }
            return false
        },
        handleRightClick(event, item, stash) {
            event.preventDefault();
            this.contextMenuItem = false;
            this.hoverMenuItem = false;
            if (item) {
                if (stash == 'stash') {
                    this.stashContext = 'stash';
                } else if (stash == 'clothing') {
                    this.stashContext = 'clothing';
                } else if (stash == 'glovebox') {
                    this.stashContext = 'glovebox';
                } else if (stash == 'trunk') {
                    this.stashContext = 'trunk';
                } else {
                    this.stashContext = false;
                }
                this.showContextMenu = true;
                this.contextMenuValue = 'main'
                this.menuPosition = { x: event.clientX - 30, y: event.clientY - 80 };
                this.contextMenuItem = item;
            }
        },
        handleDoubleClickItem(item) {
            if (item) {
                postNUI('UseItem', item)
            }
        },
        handleMouseOverHoverItem(event, item) {

            if (item) {

                if (this.infoonbottomvalue) {
                    this.infoonbottomItem = {
                        item: item,
                    }
                };
                if (this.hoverMenuShow) {
                    this.hoverMenuItem = {
                        item: item,
                        position: { x: event.clientX, y: event.clientY - 125 }
                    };
                };
                let clientY = event.clientY;
                if (this.hoverMenuShow) {
                    clientY = event.clientY - 30;
                } else {
                    clientY = event.clientY - 125;
                }

                this.showInfoValue = {
                    item: item,
                    position: { x: event.clientX, y: clientY }
                };
            }

        },
        handleMouseLeaveHoverItem() {
            this.hoverMenuItem = false;
            this.infoonbottomItem = false;
            this.showInfoValue = false;
        },
        inventoryDrag() {
            $(".main-inventory-slot").draggable({
                helper: "clone",
                revertDuration: 0,
                revert: false,
                cancel: ".body",
                containment: ".bodyinventory",
                start: function (event, ui) {
                    if (!ui.helper.data('item')) {
                        return false;

                    };
                    ui.helper.addClass("From-MainInventory")
                    const currentThema = localStorage.getItem('thema');
                    ui.helper.addClass(currentThema + "main-inventory-slot-css")
                    ui.helper.css("width", "5.4%")
                    ui.helper.css("height", "11%")
                    ui.helper.css("z-index", "1000")

                },
                drag: function (event, ui) { },
                stop: (event, ui) => {
                    ui.helper.removeClass("From-MainInventory")
                    ui.helper.removeClass("From-VehicleTrunk")
                    ui.helper.removeClass("From-RobPlayerInventory")
                    ui.helper.removeClass("From-GroundInventory")
                    ui.helper.removeClass("From-VehicleGlovebox")
                    ui.helper.removeClass("From-Backpack")
                    ui.helper.removeClass("From-ClothingInventory")
                    ui.helper.removeClass("From-StashInventory")
                    ui.helper.removeClass("From-Shop")
                    setTimeout(() => {
                        this.mainInventoryDrop()
                    }, 10)
                },
            })
            if (this.rightinventory == 'ground') {
                $(".ground-inventory-drag-slot").draggable({
                    helper: "clone",
                    revertDuration: 0,
                    revert: false,
                    cancel: ".body",
                    containment: ".bodyinventory",
                    start: function (event, ui) {
                        if (!ui.helper.data('item')) {
                            return false;

                        };
                        ui.helper.addClass("From-GroundInventory")
                        const currentThema = localStorage.getItem('thema');
                        ui.helper.addClass(currentThema + "main-inventory-slot-css")
                        ui.helper.css("width", "5.4%")
                        ui.helper.css("height", "11%")
                        ui.helper.css("z-index", "1000")

                    },
                    drag: function (event, ui) {

                    },
                    stop: (event, ui) => {

                        ui.helper.removeClass("From-MainInventory")
                        ui.helper.removeClass("From-VehicleTrunk")
                        ui.helper.removeClass("From-GroundInventory")
                        ui.helper.removeClass("From-RobPlayerInventory")
                        ui.helper.removeClass("From-Shop")
                        ui.helper.removeClass("From-VehicleGlovebox")
                        ui.helper.removeClass("From-ClothingInventory")
                        ui.helper.removeClass("From-Backpack")
                        ui.helper.removeClass("From-StashInventory")
                        setTimeout(() => {
                            this.mainInventoryDrop()
                        }, 50)
                    },
                })
            }
            if (this.rightinventory == 'stash') {
                $(".stash-inventory-drag-slot").draggable({
                    helper: "clone",
                    revertDuration: 0,
                    revert: false,
                    cancel: ".body",
                    containment: ".bodyinventory",
                    start: function (event, ui) {
                        if (!ui.helper.data('item')) {
                            return false;

                        };
                        ui.helper.addClass("From-StashInventory")
                        const currentThema = localStorage.getItem('thema');
                        ui.helper.addClass(currentThema + "main-inventory-slot-css")
                        ui.helper.css("width", "5.4%")
                        ui.helper.css("height", "11%")
                        ui.helper.css("z-index", "1000")

                    },
                    drag: function (event, ui) {

                    },
                    stop: (event, ui) => {
                        ui.helper.removeClass("From-MainInventory")
                        ui.helper.removeClass("From-VehicleTrunk")
                        ui.helper.removeClass("From-GroundInventory")
                        ui.helper.removeClass("From-StashInventory")
                        ui.helper.removeClass("From-ClothingInventory")
                        ui.helper.removeClass("From-RobPlayerInventory")
                        ui.helper.removeClass("From-Backpack")
                        ui.helper.removeClass("From-VehicleGlovebox")
                        ui.helper.removeClass("From-Shop")
                        setTimeout(() => {
                            this.mainInventoryDrop()
                        }, 50)
                    },
                })
            }
            if (this.rightinventory == 'vehicle') {
                $(".trunk-inventory-drag-slot").draggable({
                    helper: "clone",
                    revertDuration: 0,
                    revert: false,
                    cancel: ".body",
                    containment: ".bodyinventory",
                    start: function (event, ui) {
                        if (!ui.helper.data('item')) {

                            return false;

                        };
                        ui.helper.addClass("From-VehicleTrunk")
                        const currentThema = localStorage.getItem('thema');
                        ui.helper.addClass(currentThema + "main-inventory-slot-css")
                        ui.helper.css("width", "5.4%")
                        ui.helper.css("height", "11%")
                        ui.helper.css("z-index", "1000")

                    },
                    drag: function (event, ui) {

                    },
                    stop: (event, ui) => {
                        ui.helper.removeClass("From-MainInventory")
                        ui.helper.removeClass("From-VehicleTrunk")
                        ui.helper.removeClass("From-GroundInventory")
                        ui.helper.removeClass("From-Backpack")
                        ui.helper.removeClass("From-RobPlayerInventory")
                        ui.helper.removeClass("From-StashInventory")
                        ui.helper.removeClass("From-ClothingInventory")
                        ui.helper.removeClass("From-VehicleGlovebox")
                        ui.helper.removeClass("From-Shop")
                        setTimeout(() => {
                            this.mainInventoryDrop()
                        }, 50)
                    },
                })
            }
            if (this.rightinventory == 'glovebox') {
                $(".glovebox-inventory-drag-slot").draggable({
                    helper: "clone",
                    revertDuration: 0,
                    revert: false,
                    cancel: ".body",
                    containment: ".bodyinventory",
                    start: function (event, ui) {
                        if (!ui.helper.data('item')) {
                            return false;

                        };
                        ui.helper.addClass("From-VehicleGlovebox")
                        const currentThema = localStorage.getItem('thema');
                        ui.helper.addClass(currentThema + "main-inventory-slot-css")
                        ui.helper.css("width", "5.4%")
                        ui.helper.css("height", "11%")
                        ui.helper.css("z-index", "1000")

                    },
                    drag: function (event, ui) {

                    },
                    stop: (event, ui) => {
                        ui.helper.removeClass("From-MainInventory")
                        ui.helper.removeClass("From-VehicleGlovebox")
                        ui.helper.removeClass("From-VehicleTrunk")
                        ui.helper.removeClass("From-RobPlayerInventory")
                        ui.helper.removeClass("From-GroundInventory")
                        ui.helper.removeClass("From-StashInventory")
                        ui.helper.removeClass("From-Backpack")
                        ui.helper.removeClass("From-ClothingInventory")
                        ui.helper.removeClass("From-Shop")
                        setTimeout(() => {
                            this.mainInventoryDrop()
                        }, 50)
                    },
                })
            }
            if (this.rightinventory == 'shop') {
                $(".shop-inventory-drag-slot").draggable({
                    helper: "clone",
                    revertDuration: 0,
                    revert: false,
                    cancel: ".body",
                    containment: ".bodyinventory",
                    start: function (event, ui) {
                        if (!ui.helper.data('item')) {
                            return false;

                        };
                        ui.helper.addClass("From-Shop")
                        const currentThema = localStorage.getItem('thema');
                        ui.helper.addClass(currentThema + "main-inventory-slot-css")
                        ui.helper.css("width", "5.4%")
                        ui.helper.css("height", "11%")
                        ui.helper.css("z-index", "1000")

                    },
                    drag: function (event, ui) {

                    },
                    stop: (event, ui) => {
                        ui.helper.removeClass("From-MainInventory")
                        ui.helper.removeClass("From-Shop")
                        ui.helper.removeClass("From-VehicleTrunk")
                        ui.helper.removeClass("From-RobPlayerInventory")
                        ui.helper.removeClass("From-Backpack")
                        ui.helper.removeClass("From-GroundInventory")
                        ui.helper.removeClass("From-StashInventory")
                        ui.helper.removeClass("From-ClothingInventory")
                        setTimeout(() => {
                            this.mainInventoryDrop()
                        }, 50)
                    },
                })
            }
            if (this.rightinventory == 'backpack') {
                $(".backpack-inventory-drag-slot").draggable({
                    helper: "clone",
                    revertDuration: 0,
                    revert: false,
                    cancel: ".body",
                    containment: ".bodyinventory",
                    start: function (event, ui) {
                        if (!ui.helper.data('item')) {
                            return false;

                        };
                        ui.helper.addClass("From-Backpack")
                        const currentThema = localStorage.getItem('thema');
                        ui.helper.addClass(currentThema + "main-inventory-slot-css")
                        ui.helper.css("width", "5.4%")
                        ui.helper.css("height", "11%")
                        ui.helper.css("z-index", "1000")

                    },
                    drag: function (event, ui) {

                    },
                    stop: (event, ui) => {
                        ui.helper.removeClass("From-MainInventory")
                        ui.helper.removeClass("From-Shop")
                        ui.helper.removeClass("From-RobPlayerInventory")
                        ui.helper.removeClass("From-VehicleTrunk")
                        ui.helper.removeClass("From-GroundInventory")
                        ui.helper.removeClass("From-StashInventory")
                        ui.helper.removeClass("From-Backpack")
                        ui.helper.removeClass("From-ClothingInventory")
                        setTimeout(() => {
                            this.mainInventoryDrop()
                        }, 50)
                    },
                })
            }
            if (this.rightinventory == 'player') {

                $(".rob-player-inventory-slot").draggable({
                    helper: "clone",
                    revertDuration: 0,
                    revert: false,
                    cancel: ".body",
                    containment: ".bodyinventory",
                    start: function (event, ui) {
                        if (!ui.helper.data('item')) {
                            return false;

                        };
                        ui.helper.addClass("From-RobPlayerInventory")
                        const currentThema = localStorage.getItem('thema');
                        ui.helper.addClass(currentThema + "main-inventory-slot-css")
                        ui.helper.css("width", "5.4%")
                        ui.helper.css("height", "11%")
                        ui.helper.css("z-index", "1000")


                    },
                    drag: function (event, ui) {

                    },
                    stop: (event, ui) => {

                        ui.helper.removeClass("From-MainInventory")
                        ui.helper.removeClass("From-RobPlayerInventory")
                        ui.helper.removeClass("From-Shop")
                        ui.helper.removeClass("From-VehicleTrunk")
                        ui.helper.removeClass("From-GroundInventory")
                        ui.helper.removeClass("From-StashInventory")
                        ui.helper.removeClass("From-Backpack")
                        ui.helper.removeClass("From-ClothingInventory")
                        setTimeout(() => {
                            this.mainInventoryDrop()
                        }, 50)
                    },
                })
            }

            if (this.configClothing) {
                $(".clothes-slot-drag").draggable({
                    helper: "clone",
                    revertDuration: 0,
                    revert: false,
                    cancel: ".body",
                    containment: ".bodyinventory",
                    start: function (event, ui) {
                        if (!ui.helper.data('item')) {
                            return false;

                        };
                        ui.helper.addClass("From-ClothingInventory")
                        const currentThema = localStorage.getItem('thema');
                        const layout = localStorage.getItem('layout');
                        ui.helper.addClass(currentThema + "main-inventory-slot-css")
                        if (layout == 2) {
                            ui.helper.css("width", "18.4%")
                            ui.helper.css("height", "11%")
                        }
                        ui.helper.css("z-index", "1000")
                        ui.helper.css("position", "absolute")

                    },
                    drag: function (event, ui) {

                    },
                    stop: (event, ui) => {

                        ui.helper.removeClass("From-MainInventory")
                        ui.helper.removeClass("From-RobPlayerInventory")
                        ui.helper.removeClass("From-Shop")
                        ui.helper.removeClass("From-VehicleTrunk")
                        ui.helper.removeClass("From-GroundInventory")
                        ui.helper.removeClass("From-StashInventory")
                        ui.helper.removeClass("From-Backpack")
                        ui.helper.removeClass("From-ClothingInventory")
                        setTimeout(() => {
                            this.mainInventoryDrop()
                        }, 50)
                    },
                })

            }




        },
        mainInventoryDrop() {
            $(".main-inventory-slot-drop").droppable({
                tolerance: "pointer",
                drop: (event, ui) => {

                    let itemFrom = $(ui.helper).hasClass("From-MainInventory");
                    clicksound('m-inventory-slotdrag.mp3');
                    if (itemFrom) {

                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');

                        let movingItem = this.PlayerInventory[itemName.slot];
                        if (movingItem) {
                            let oldItemSlot = movingItem.slot;
                            let targetItem = this.PlayerInventory[newItemSlot];
                            if (Number(oldItemSlot) === Number(newItemSlot)) return;

                            if (targetItem) {
                                postNUI('SwapMainInventoryTargetItem', { oldSlot: oldItemSlot, newSlot: newItemSlot })

                            } else {
                                postNUI('SwapMainInventory', { oldSlot: oldItemSlot, newSlot: newItemSlot })
                            }
                        }
                        return
                    }
                    let itemFromGround = $(ui.helper).hasClass("From-GroundInventory");
                    if (itemFromGround) {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');

                        let movingItem = this.rightInventoryData && this.rightInventoryData.inventory[itemName.slot];

                        if (movingItem) {
                            let oldItemSlot = movingItem.slot;
                            postNUI('swapGroundToMainInventory', { oldSlot: oldItemSlot, newSlot: newItemSlot })
                        } else {
                            movingItem = {}
                        }
                        return
                    }
                    let itemFromStash = $(ui.helper).hasClass("From-StashInventory");
                    if (itemFromStash) {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let movingItem = this.rightInventoryData && this.rightInventoryData.inventory[itemName.slot];
                        if (movingItem) {
                            let oldItemSlot = movingItem.slot;
                            if (this.rightInventoryData.stashId == null) {
                                this.notification(this.locales['UNKOWNSTASHNAME']);
                                return;
                            }
                            postNUI('swapStashToMainInventory', { oldSlot: oldItemSlot, newSlot: newItemSlot, stashId: this.rightInventoryData.stashId })
                        } else {
                            movingItem = {}
                        }
                        return
                    }
                    let itemFromVehicleTrunk = $(ui.helper).hasClass("From-VehicleTrunk");
                    if (itemFromVehicleTrunk) {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let movingItem = this.rightInventoryData && this.rightInventoryData.trunk[itemName.slot];
                        if (movingItem) {
                            let oldItemSlot = movingItem.slot;
                            if (this.rightInventoryData.plate == null) {
                                this.notification(this.locales['NOTFOUNDPLATE']);
                                return;
                            }
                            clicksound('m-inventory-slotdrag.mp3');
                            postNUI('swapVehicleTrunkToMainInventory', { oldSlot: oldItemSlot, newSlot: newItemSlot, plate: this.rightInventoryData.plate, maxslot: this.rightInventoryData.slot, weight: this.rightInventoryData.maxweight })
                        } else {
                            movingItem = {}
                        }

                        return
                    }
                    let itemFromVehicleGlovebox = $(ui.helper).hasClass("From-VehicleGlovebox");
                    if (itemFromVehicleGlovebox) {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let movingItem = this.rightInventoryData && this.rightInventoryData.glovebox[itemName.slot];
                        if (movingItem) {
                            let oldItemSlot = movingItem.slot;
                            if (this.rightInventoryData.plate == null) {
                                this.notification(this.locales['NOTFOUNDPLATE']);
                                return;
                            }
                            clicksound('m-inventory-slotdrag.mp3');
                            postNUI('swapVehicleGloveboxToMainInventory', { oldSlot: oldItemSlot, newSlot: newItemSlot, plate: this.rightInventoryData.plate, maxslot: this.rightInventoryData.slot, weight: this.rightInventoryData.maxweight })
                        } else {
                            movingItem = {}
                        }

                        return
                    }
                    let itemFromShop = $(ui.helper).hasClass("From-Shop");
                    if (itemFromShop) {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        if (!itemName) {
                            return;
                        }
                        if (this.rightInventoryData.shopname == null) {
                            return;
                        }
                        postNUI('swapShopToMainInventory', { newSlot: newItemSlot, itemname: itemName, shopname: this.rightInventoryData.shopname, amount: this.shopAmount, paymentMethod: this.paymentMethod })


                        return
                    }
                    let itemFromBackpack = $(ui.helper).hasClass("From-Backpack");
                    if (itemFromBackpack) {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        if (!itemName) {
                            return;
                        }
                        if (this.rightInventoryData.backpackname == null) {
                            return;
                        }
                        postNUI('swapBackpackToIventory', { newSlot: newItemSlot, itemname: itemName, backpackname: this.rightInventoryData.backpackname })
                        return
                    }
                    let itemRobPlayer = $(ui.helper).hasClass("From-RobPlayerInventory");
                    if (itemRobPlayer) {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        if (!itemName) {
                            return;
                        }
                        if (this.rightInventoryData.playerid == null) {
                            this.notification(this.locales['NOTFOUNDPLAYER']);
                            return;
                        }
                        postNUI('swapRobPlayerToMainInventory', { newSlot: newItemSlot, itemname: itemName, playerid: this.rightInventoryData.playerid })
                        return
                    }
                    let itemFromClothingInventory = $(ui.helper).hasClass("From-ClothingInventory");
                    if (itemFromClothingInventory) {
                        let itemName = $(ui.helper).data('item');
                        if (!itemName) {
                            return;
                        }
                        postNUI('swapClothingToMainInventory', { itemname: itemName })
                        return
                    }

                },
            });
            if (this.rightinventory == 'ground') {
                $(".ground-inventory-drop-slot").droppable({
                    tolerance: "pointer",
                    drop: (event, ui) => {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let movingItem = this.PlayerInventory[itemName.slot];
                        let itemFrom = $(ui.helper).hasClass("From-GroundInventory");
                        if (itemFrom) {
                            return
                        }
                        if (movingItem) {
                            clicksound('m-inventory-dropitem.mp3');
                            let oldItemSlot = movingItem.slot;
                            postNUI('swapMainInventoryToGround', { oldSlot: oldItemSlot, newSlot: newItemSlot })
                        }
                    },
                });

            }
            if (this.rightinventory == 'stash') {
                $(".stash-inventory-drop-slot").droppable({
                    tolerance: "pointer",
                    drop: (event, ui) => {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let movingItem = this.PlayerInventory[itemName.slot];
                        let itemFrom = $(ui.helper).hasClass("From-StashInventory");
                        if (itemFrom) {
                            clicksound('m-inventory-slotdrag.mp3');
                            postNUI('swapMainStashToStash', { oldSlot: itemName.slot, newSlot: newItemSlot, stashId: this.rightInventoryData.stashId })
                            return;
                        }
                        if (movingItem) {
                            let oldItemSlot = movingItem.slot;
                            if (this.rightInventoryData.stashId) {
                                clicksound('m-inventory-dropitem.mp3');
                                postNUI('swapMainInventoryToStash', { oldSlot: oldItemSlot, newSlot: newItemSlot, stashId: this.rightInventoryData.stashId, maxslot: this.rightInventoryData.slot, weight: this.rightInventoryData.maxweight })
                            }
                        }
                    },
                });
            }
            if (this.rightinventory == 'vehicle') {
                $(".trunk-inventory-drop-slot").droppable({
                    tolerance: "pointer",
                    drop: (event, ui) => {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let itemFrom = $(ui.helper).hasClass("From-MainInventory");
                        if (itemFrom) {
                            if (this.rightInventoryData.plate == null) {
                                this.notification(this.locales['NOTFOUNDPLATE']);
                                return;
                            }
                            clicksound('m-inventory-dropitem.mp3');
                            postNUI('swapMainInventoryToVehicleTrunk', { oldSlot: itemName.slot, newSlot: newItemSlot, plate: this.rightInventoryData.plate, maxslot: this.rightInventoryData.slot, weight: this.rightInventoryData.maxweight })
                            return;
                        }
                    },
                });
            }
            if (this.rightinventory == 'glovebox') {
                $(".glovebox-inventory-drop-slot").droppable({
                    tolerance: "pointer",
                    drop: (event, ui) => {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let itemFrom = $(ui.helper).hasClass("From-MainInventory");
                        if (itemFrom) {
                            if (this.rightInventoryData.plate == null) {
                                this.notification(this.locales['NOTFOUNDPLATE']);
                                return;
                            }
                            clicksound('m-inventory-dropitem.mp3');
                            postNUI('swapMainInventoryToVehicleGlovebox', { oldSlot: itemName.slot, newSlot: newItemSlot, plate: this.rightInventoryData.plate, maxslot: this.rightInventoryData.slot, weight: this.rightInventoryData.maxweight })
                            return;
                        }
                    },
                });
            }
            if (this.rightinventory == 'backpack') {

                $(".backpack-inventory-drag-drop").droppable({
                    tolerance: "pointer",
                    drop: (event, ui) => {

                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let itemFrom = $(ui.helper).hasClass("From-MainInventory");
                        if (itemFrom) {
                            if (this.rightInventoryData.backpackname == null) {
                                this.notification(this.locales['UNKOWNSTASHNAME']);
                                return;
                            }
                            clicksound('m-inventory-dropitem.mp3');
                            postNUI('swapMainInventoryToBackpack', { oldSlot: itemName.slot, newSlot: newItemSlot + 1, backpackname: this.rightInventoryData.backpackname, maxslot: this.rightInventoryData.slot, weight: this.rightInventoryData.maxweight })
                            return;
                        }
                    },
                });
            }
            if (this.rightinventory == 'player') {
                $(".rob-player-inventory-slot-drop").droppable({
                    tolerance: "pointer",
                    drop: (event, ui) => {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let itemFrom = $(ui.helper).hasClass("From-MainInventory");
                        if (itemFrom) {
                            if (this.rightInventoryData.playerid == null) {
                                this.notification(this.locales['NOTFOUNDPLAYER']);
                                return;
                            }
                            clicksound('m-inventory-dropitem.mp3');
                            postNUI('swapMainInventoryToRobPlayer', { oldSlot: itemName.slot, newSlot: newItemSlot, playerid: this.rightInventoryData.playerid })
                            return;
                        }
                    },
                });
            }
            if (this.configClothing) {

                $(".clothes-slot-drop ").droppable({
                    tolerance: "pointer",
                    drop: (event, ui) => {
                        let itemName = $(ui.helper).data('item');
                        let itemFrom = $(ui.helper).hasClass("From-MainInventory");
                        if (itemName && itemFrom) {
                            clicksound('m-inventory-dropitem.mp3');
                            postNUI('swapMainInventoryToClothingInventory', { itemname: itemName })
                            return;
                        }
                    },
                });
            }

            if (this.layout == 2) {
                $(".drop-slot-drop").droppable({
                    tolerance: "pointer",
                    drop: (event, ui) => {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let movingItem = this.PlayerInventory[itemName.slot];
                        let itemFrom = $(ui.helper).hasClass("From-GroundInventory");
                        if (itemFrom) {
                            return
                        }
                        if (movingItem) {
                            clicksound('m-inventory-dropitem.mp3');
                            let oldItemSlot = movingItem.slot;
                            postNUI('swapMainInventoryToGround', { oldSlot: oldItemSlot })
                        }
                    },
                });
                $(".use-slot-drop").droppable({
                    tolerance: "pointer",
                    drop: (event, ui) => {
                        let itemName = $(ui.helper).data('item');
                        let newItemSlot = $(event.target).data('slotnumber');
                        let movingItem = this.PlayerInventory[itemName.slot];
                        let itemFrom = $(ui.helper).hasClass("From-GroundInventory");
                        if (itemFrom) {
                            return
                        }
                        if (movingItem) {
                            clicksound('m-inventory-dropitem.mp3');
                            postNUI('UseItem', movingItem)
                        }
                    },
                });


            }

        },
        layout2weight() {
            let weightPercentage = this.PlayerInventoryWeight / this.maxWeight;
            let strokeColor;

            if (weightPercentage <= 1 / 3) {
                strokeColor = '#FFFFFF';
                this.weighticon = 'whitebag'
            } else if (weightPercentage <= 2 / 3) {
                strokeColor = '#FF8833';
                this.weighticon = 'orangebag'
            } else {
                strokeColor = '#FF3333';
                this.weighticon = 'redbag'
            }
            if (!this.heightbar) {
                this.heightbar = new ProgressBar.Path('#slot-weight', {
                    easing: 'easeInOut',
                    duration: 1400,
                });
            }
            document.querySelector('#slot-weight').setAttribute('stroke', strokeColor);
            this.heightbar.animate(weightPercentage);
        },
        eventHandler(event) {
            switch (event.data.action) {
                case "PLAYERNAME_ID":
                    this.playerInfo.name = event.data.payload.playername;
                    this.playerInfo.id = event.data.payload.playerid;
                    this.playerInfo.job = event.data.payload.joblabel;
                    this.playerInfo.jobgrade = event.data.payload.gradename;
                    break;
                case "CONFIG_SETTINGS":
                    this.craftingItems = event.data.payload.configcraftitem;
                    this.allowedCraft = event.data.payload.configcraft;
                    this.maxWeight = event.data.payload.playerweight / 1000;
                    this.maxSlot = event.data.payload.maxslot;
                    this.configClothing = event.data.payload.configclothing;
                    // this.cashitem = event.data.payload.cashitem;
                    this.serverlogo = event.data.payload.serverlogo;
                    this.contextMenuData = event.data.payload.context;
                    this.adjustmentsData = event.data.payload.adjust;
                    this.groundslot = event.data.payload.groundslot;

                    let thema = localStorage.getItem('thema');
                    let layout = localStorage.getItem('layout');
                    let lights = localStorage.getItem('lights');
                    this.adjustmentsData.forEach((item) => {
                        const storedValue = localStorage.getItem(item.name);
                        item.value = storedValue === 'true' ? true : false;
                        if (item.name == 'hoverinfo') {
                            this.hoverMenuShow = item.value
                        }
                        if (item.name == 'infoonbottom') {
                            this.infoonbottomvalue = item.value
                        }
                        if (item.name == 'lights') {
                            if (item.value) {
                                this.lights = 'background2'
                            } else {
                                this.lights = 'background1'
                            }
                        }
                        if (item.name == 'soundfx') {
                            soundFx = item.value
                        }
                        if (item.name == 'lights') {
                            if (this.layout == 1) {
                                if (item.value) {
                                    this.lights = 'layout1light'
                                } else {
                                    this.lights = 'layout1notlight'
                                }
                            } else {
                                if (item.value) {
                                    this.lights = 'layout2light'
                                } else {
                                    this.lights = 'layout2notlight'
                                }
                            }

                        }
                    })

                    if (thema) {
                        this.currentThema = thema
                    } else {
                        this.currentThema = 'blue'
                    }
                    if (layout) {
                        this.layout = layout
                    } else {
                        this.layout = 1
                    }
                    this.Category = event.data.payload.category
                    if (this.layout == 2) {
                        postNUI('DisablePedScreen')
                    } else {
                        postNUI('EnablePedScreen')
                    }
                    break;

                case "SHOW_BOTTOM_MENU":
                    this.bottommenu(event.data.payload)
                    break;
                case "CLOSE_INVENTORY":
                    this.show = false;
                    this.rightInventoryData = false;
                    this.rightinventory = 'ground'
                    this.craftingPage = false;

                    break;
                case "CHECK_NUI":
                    postNUI('LoadedNUI')
                    break;
                case "LOAD_INVENTORY":
                    this.craftingPage = false;
                    this.contextMenuValue = 'main'
                    this.searchInventoryItem = ''
                    this.filterCategoryName = 'all'
                    this.showContextMenu = false;
                    this.contextMenuItem = false;
                    this.show = true;
                    this.PlayerInventory = []
                    this.PlayerInventory = event.data.payload;
                    this.PlayerInventoryWeight = Object.values(this.PlayerInventory).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;
                    if (this.layout == 1) {

                        this.progressBar.weight.animate(this.PlayerInventoryWeight / this.maxWeight);


                    } else {
                        this.layout2weight()
                    }

                    setTimeout(() => {
                        this.inventoryDrag()
                        this.mainInventoryDrop()
                    }, 100)
                    break;

                case "UPDATE_INVENTORY":
                    this.PlayerInventory = []
                    this.PlayerInventory = event.data.payload;
                    this.PlayerInventoryWeight = Object.values(this.PlayerInventory).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;

                    if (this.layout == 1) {

                        this.progressBar.weight.animate(this.PlayerInventoryWeight / this.maxWeight);

                    } else {
                        this.layout2weight()
                    }
                    setTimeout(() => {
                        this.inventoryDrag()
                        this.mainInventoryDrop()
                    }, 100)
                    break;
                case "UPDATE_GROUND":
                    if (this.rightinventory === 'ground') {
                        this.rightinventory = 'ground'
                        this.rightInventoryData = event.data.payload;
                        setTimeout(() => {
                            this.inventoryDrag()
                            this.mainInventoryDrop()
                        }, 150)

                    }
                    break;
                case "CLOSE_RIGHTINVENTORY":
                    this.rightinventory = 'ground'
                    this.rightInventoryData = false;
                    break;
                case "CLOSE_GROUND":
                    if (this.rightinventory === 'ground') {
                        this.rightinventory = 'ground'
                        this.rightInventoryData = false;
                    }

                    break;
                case "OPEN_STASH":
                    this.rightinventory = 'stash'
                    this.rightInventoryData = event.data.payload.inventory;
                    this.rightInventoryWeight = Object.values(this.rightInventoryData.inventory).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;
                    setTimeout(() => {
                        this.inventoryDrag()
                        this.mainInventoryDrop()
                    }, 50)
                    break;
                case "UPDATE_STASH":
                    if (this.rightinventory == 'stash' && this.rightInventoryData.stashId == event.data.payload.stashid) {
                        this.rightInventoryData.inventory = event.data.payload.inventory;
                        this.rightInventoryWeight = Object.values(this.rightInventoryData.inventory).reduce((total, item) => {
                            return total + (item.weight * item.amount);
                        }, 0) / 1000;
                    }
                    setTimeout(() => {
                        this.inventoryDrag()
                        this.mainInventoryDrop()
                    }, 50)
                    break;
                case "LOAD_VEHICLE_GLOVEBOX":
                    this.rightinventory = 'glovebox'
                    this.rightInventoryData = event.data.payload;
                    let itemdata = Object.values(this.rightInventoryData.glovebox)
                    if (itemdata.length < 0) {
                        this.rightInventoryWeight = 0
                        return
                    }
                    this.rightInventoryWeight = Object.values(this.rightInventoryData.glovebox).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;
                    setTimeout(() => {
                        this.inventoryDrag()
                        this.mainInventoryDrop()
                    }, 50)
                    break;
                case "LOAD_VEHICLE_INVENTORY":
                    if (!this.show) {
                        this.show = true;
                    }
                    this.rightinventory = 'vehicle'
                    this.rightInventoryData = event.data.payload;
                    this.rightInventoryWeight = Object.values(this.rightInventoryData.trunk).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;
                    setTimeout(() => {
                        this.inventoryDrag()
                        this.mainInventoryDrop()
                    }, 50)
                    break;
                case "UPDATE_VEHICLE_INVENTORY":
                    this.rightInventoryData.trunk = event.data.payload.trunk;
                    this.rightInventoryWeight = Object.values(this.rightInventoryData.trunk).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;
                    break;
                case "UPDATE_GLOVEBOX_INVENTORY":
                    this.rightInventoryData.glovebox = event.data.payload.glovebox;
                    this.rightInventoryWeight = Object.values(this.rightInventoryData.glovebox).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;
                    break;
                case "SET_STATUS":
                    this.status[event.data.payload.type] = event.data.payload.value
                    break
                case "OPEN_SHOP":
                    this.rightinventory = 'shop'
                    this.rightInventoryData = event.data.payload;
                    break;
                case "TOGGLE_HOTBAR":
                    this.hotBar = event.data.payload;
                    break;
                case "NOTIFICATION":
                    this.notification(event.data.payload);
                    break;
                case "REMOVE_BACKPACK":
                    this.rightinventory = 'ground'
                    this.rightInventoryData = false;
                    break;
                case "OPEN_BACKPACK":
                    this.rightinventory = 'backpack'
                    this.rightInventoryData = event.data.payload;
                    this.rightInventoryWeight = Object.values(this.rightInventoryData.inventory).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;
                    setTimeout(() => {
                        this.inventoryDrag()
                        this.mainInventoryDrop()
                    }, 50)
                    break;
                case "LOAD_BACKPACK":
                    if (this.rightinventory == 'backpack') {
                        this.rightInventoryData.inventory = event.data.payload;
                    }
                    this.rightInventoryWeight = Object.values(this.rightInventoryData.inventory).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;
                    setTimeout(() => {
                        this.inventoryDrag()
                        this.mainInventoryDrop()
                    }, 50)
                    break;
                case "OPEN_PLAYER_INVENTORY":
                    this.rightinventory = 'player'
                    this.rightInventoryData = event.data.payload;
                    this.rightInventoryWeight = Object.values(this.rightInventoryData.inventory).reduce((total, item) => {
                        return total + (item.weight * item.amount);
                    }, 0) / 1000;
                    setTimeout(() => {
                        this.inventoryDrag()
                        this.mainInventoryDrop()
                    }, 50)
                    break;
                case "UPDATE_ROB_PLAYER_INVENTORY":
                    if (this.rightinventory == 'player') {
                        this.rightInventoryData.inventory = event.data.payload
                    }
                    break;
                case "SET_LOCALES":
                    this.locales = event.data.payload;
                    break;
                case "UPDATE_CLOTHING_INVENTORY":
                    this.ClothingInventory = event.data.payload;
                    break;
                default:
                    break
            }

        },
        keyHandler(e) {
            switch (e.keyCode) {
                case 27:
                    postNUI('CloseInventory')
                    this.show = false;
                    if (this.rightinventory == 'player') {
                        if (this.rightInventoryData.playerid) {
                            postNUI('ChangePlayerRobStatus', { playerid: this.rightInventoryData.playerid })
                        }
                    }
                    break;
                default:
                    break;
            }

        },
    },

    computed: {
        contextMenuDataComputed() {
            if (this.contextMenuItem) {
                if (this.stashContext == 'stash') {
                    if (this.contextMenuItem.amount > 1) {
                        return [{ name: 'split', label: this.locales['SPLITITEM'], icon: 'splititemicon' }];
                    } else {
                        return [];
                    }
                }
                if (this.stashContext == 'glovebox') {
                    if (this.contextMenuItem.amount > 1) {
                        return [{ name: 'split', label: this.locales['SPLITITEM'], icon: 'splititemicon' }];
                    } else {
                        return [];
                    }
                }
                if (this.stashContext == 'trunk') {
                    if (this.contextMenuItem.amount > 1) {
                        return [{ name: 'split', label: this.locales['SPLITITEM'], icon: 'splititemicon' }];
                    } else {
                        return [];
                    }
                }


                const hasInfo = !!this.contextMenuItem.info;
                const hasAttachments = hasInfo && Array.isArray(this.contextMenuItem.info.attachments) && this.contextMenuItem.info.attachments.length > 0;
                const hasTint = hasInfo && this.contextMenuItem.info.tint > 0;

                const menuOptions = [...this.contextMenuData];

                if (hasInfo) {
                    menuOptions.push({ name: 'info', label: this.locales['ITEMINFO'], icon: 'metainfoicon' });
                }
                if (hasAttachments) {
                    menuOptions.push({ name: 'attachment', label: this.locales['ATTACHMENT'], icon: "attachment" });
                }
                if (hasTint) {
                    menuOptions.push({ name: 'tint', label: this.locales['TINT'], icon: "tinticon" });
                }
                if (this.contextMenuItem.amount > 1) {
                    menuOptions.push({ name: 'split', label: this.locales['SPLITITEM'], icon: 'splititemicon' });
                }

                return menuOptions;
            } else {
                return this.contextMenuData;
            }
        },


        inventoryItemsArray() {
            const items = {};
            Object.values(this.PlayerInventory).forEach(item => {
                const itemName = item.name ? item.name.toLowerCase() : '';
                const itemLabel = item.label ? item.label.toLowerCase() : '';
                const searchLower = this.searchInventoryItem.toLowerCase();

                const matchesCategory = this.filterCategoryName === 'all' || item.type === this.filterCategoryName;
                const matchesSearchText = itemName.includes(searchLower) || itemLabel.includes(searchLower);

                if (matchesCategory && matchesSearchText) {
                    items[item.slot] = item;
                }
            });
            return items;
        },
        clothingInventoryComputed() {
            const citems = {};
            if (this.ClothingInventory) {
                let itemdata = Object.values(this.ClothingInventory)
                if (itemdata.length > 0) {
                    itemdata.forEach(item => {
                        citems[item.name] = item;
                    });
                }
                return citems;

            }

        },

        rightinventoryItems() {
            const items = {};
            if (this.rightinventory === 'ground') {
                if (this.rightInventoryData) {
                    let itemdata = Object.values(this.rightInventoryData.inventory)
                    if (itemdata.length > 0) {
                        itemdata.forEach(item => {
                            items[item.slot] = item;
                        });
                    }
                }
                return items;
            }
            if (this.rightinventory === 'stash') {
                if (this.rightInventoryData) {
                    let itemdata = Object.values(this.rightInventoryData.inventory)
                    if (itemdata.length > 0) {
                        itemdata.forEach(item => {
                            items[item.slot] = item;
                        });
                    }
                }
                return items;
            }
            if (this.rightinventory === 'vehicle') {
                if (this.rightInventoryData) {
                    let itemdata = Object.values(this.rightInventoryData.trunk)
                    if (itemdata.length > 0) {
                        itemdata.forEach(item => {
                            items[item.slot] = item;
                        });
                    }
                }
                return items;
            }
            if (this.rightinventory === 'glovebox') {
                if (this.rightInventoryData) {
                    let itemdata = Object.values(this.rightInventoryData.glovebox)
                    if (itemdata.length > 0) {
                        itemdata.forEach(item => {
                            items[item.slot] = item;
                        });
                    }
                }
                return items;
            }
            if (this.rightinventory === 'player') {
                if (this.rightInventoryData) {
                    let itemdata = Object.values(this.rightInventoryData.inventory)
                    if (itemdata.length > 0) {
                        itemdata.forEach(item => {
                            items[item.slot] = item;
                        });
                    }
                }
                return items;
            }

        }

    },
    mounted() {

        if (this.layout == 1) {

            this.setupHudProgressbar('health', '#FF4848', '#ff48482d')
            this.setupHudProgressbar('armor', '#4870FF', '#4870FF2d')
            this.setupHudProgressbar('hunger', '#FFA048', '#FFA0482d')
            this.setupHudProgressbar('thirst', '#48FFF4', '#48FFF42d')
            this.setupHudProgressbar('stamina', '#C4FF48', '#C4FF482d')

            if (!this.cashitem) {
                this.setupHudProgressbar('cash', '#C4FF48', '#C4FF482d')
                this.progressBar.cash.animate(1.0)
            }
            this.setupHudProgressbar('bank', '#ffffff', '#ffffff37')
            this.setupHudProgressbar('weight', '#FF8934', '#FF89342d')

            this.progressBar.bank.animate(1.0)


        };


        window.addEventListener('message', this.eventHandler);
        window.addEventListener("keyup", this.keyHandler);
        window.addEventListener('keydown', this.handleKeyDown);
        this.contextMenuItem = false;
        setTimeout(() => {
            this.inventoryDrag()
            this.mainInventoryDrop()

        }, 50)

    },
    watch: {
        'status.health'(val) {

            val ? val.toFixed(1) : 0
            this.progressBar.health.animate(val / 100);  // Number from 0.0 to 1.0


        },
        'status.armor'(val) {

            val ? val.toFixed(1) : 0
            this.progressBar.armor.animate(val / 100);  // Number from 0.0 to 1.0

        },
        'status.hunger'(val) {

            val ? val.toFixed(1) : 0
            this.progressBar.hunger.animate(val / 100);  // Number from 0.0 to 1.0

        },
        'status.thirst'(val) {

            val ? val.toFixed(1) : 0
            this.progressBar.thirst.animate(val / 100);  // Number from 0.0 to 1.0      

        },
        'status.stamina'(val) {

            val ? val.toFixed(1) : 0
            this.progressBar.stamina.animate(val / 100);  // Number from 0.0 to 1.0

        },

    },
});

app.use(store).mount("#app");


var resourceName = "codem-inventory";

if (window.GetParentResourceName) {
    resourceName = window.GetParentResourceName();
}

window.postNUI = async (name, data) => {
    try {
        const response = await fetch(`https://${resourceName}/${name}`, {
            method: "POST",
            mode: "cors",
            cache: "no-cache",
            credentials: "same-origin",
            headers: {
                "Content-Type": "application/json"
            },
            redirect: "follow",
            referrerPolicy: "no-referrer",
            body: JSON.stringify(data)
        });
        return !response.ok ? null : response.json();
    } catch (error) {
    }
};

function clicksound(val) {
    if (!soundFx) return;
    let audioPath = `./sound/${val}`;
    audioPlayer = new Howl({
        src: [audioPath]
    });
    audioPlayer.volume(0.8);
    audioPlayer.play();
}
