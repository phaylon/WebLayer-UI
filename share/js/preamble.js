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
        if (cb_name == '!VAR') {
            return this.getVar(comp, name);
        }
        return this.getters[cb_name](comp);
    },
    setValue: function (comp, name, value) {
        var cb_name = this.extractAPI(comp, 'set', name);
        if (cb_name == '!VAR') {
            return this.setVar(comp, name, value);
        }
        this.setters[cb_name](comp, value);
        return true;
    },
    getVar: function (comp, name) {
        if (!comp.data().wluiVars) {
            comp.data().wluiVars = {};
        }
        return comp.data().wluiVars[name];
    },
    setVar: function (comp, name, value) {
        if (!comp.data().wluiVars) {
            comp.data().wluiVars = {};
        }
        comp.data().wluiVars[name] = value;
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
    request: function (pos, settings_builder, values, aliased) {
        var data = {};
        var me = this;
        $.each(aliased, function (name, alias) {
            data[alias] = me.get(pos, name);
        });
        $.each(values, function (index, value) {
            data[value] = me.get(pos, value);
        });
        var settings = settings_builder(data);
        $.ajax(settings);
        return true;
    },
    collSetAll: function (pos, mappings, rows) {
        $('> *:not([class~="prototype"])', pos).remove();
        var proto = $('> *[class~="prototype"]', pos);
        var me = this;
        $.each(rows, function (i, item_data) {
            var elem = proto.clone();
            $.each(item_data, function (key, value) {
                var field = mappings[key];
                if (field != undefined) {
                    me.set(elem, field, value);
                }
            });
            $(pos).append(elem);
            $(elem).removeClass('prototype');
            $(elem).show();
        });
        return true;
    },
    collGetAll: function (pos, mappings) {
        var rows = [];
        var me = this;
        $('> *:not([class~="prototype"])', pos)
            .each(function (i, elem) {
                var item_data = {};
                $.each(mappings, function (key, field) {
                    item_data[key] = me.get(elem, field);
                });
                rows.push(item_data);
            });
        return rows;
    },
    flattenResponse: function (data, prefix) {
        var flat = {};
        var me = this;
        $.each(data, function (key, value) {
            var current = key;
            if (prefix) {
                current = prefix + '.' + key;
            }
            if (value instanceof Object && !(value instanceof Array)) {
                var lower = me.flattenResponse(value, current);
                $.each(lower, function (lkey, lvalue) {
                    flat[lkey] = lvalue;
                });
            }
            else {
                flat[current] = value;
            }
        });
        return flat;
    }
};
