"use strict";

var wlui = {
    getters: {},
    setters: {},
    findBarrier: function (pos) {
        return $(pos).closest('*[data-wlui-barrier="true"]');
    },
    getBelow: function (root, name, mark, notfound_cb) {
        var found = $(mark, root);
        if (found.length < 1) {
            return notfound_cb();
        }
        else if (found.length > 1) {
            console.log('too many outputs', mark, found);
            return false;
        }
        return this.getValue(found.first(), name);
    },
    setBelow: function (root, name, mark, value, notfound_cb) {
        var found = $(mark, root);
        if (found.length < 1) {
            return notfound_cb();
        }
        var me = this;
        found.each(function (i, comp) {
            me.setValue($(comp), name, value);
        });
    },
    get: function (pos, name) {
        var barrier = this.findBarrier(pos);
        var mark    = '*[data-wlui-out~="' + name + '"]';
        var me      = this;
        if (barrier.length) {
            return this.getBelow(barrier, name, mark, function () {
                return me.get(barrier.parent(), name);
            });
        }
        else {
            return this.getBelow(document, name, mark, function () {
                return false;
            });
        }
    },
    set: function (pos, name, value) {
        var barrier = this.findBarrier(pos);
        var mark    = '*[data-wlui-in~="' + name + '"]';
        var me      = this;
        if (barrier.length) {
            return this.setBelow(barrier, name, mark, value, function () {
                return me.set(barrier.parent(), name, value);
            });
        }
        else {
            return this.setBelow(document, name, mark, value, function () {
                return false;
            });
        }
    },
    extractAPI: function (comp, type, name) {
        return comp.data()["wluiApi"][type][name];
    },
    getValue: function (comp, name) {
        var cb_name = this.extractAPI(comp, 'get', name);
        return this.getters[cb_name](comp);
    },
    setValue: function (comp, name, value) {
        var cb_name = this.extractAPI(comp, 'set', name);
        this.setters[cb_name](comp, value);
        return true;
    },
    addGetter: function (cb_name, cb) {
        this.getters[cb_name] = cb;
        return true;
    },
    addSetter: function (cb_name, cb) {
        this.setters[cb_name] = cb;
        return true;
    },
    request: function (pos, settings_builder, values) {
        var data = {};
        var me = this;
        $.each(values, function (index, value) {
            data[value] = me.get(pos, value);
        });
        var settings = settings_builder(data);
        $.ajax(settings);
        return true;
    }
};
