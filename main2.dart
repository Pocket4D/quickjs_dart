import 'package:quickjs_dart/quickjs_dart.dart';

const String framework = r"""
class Observer {
	constructor() {
		this.currentWatcher = undefined;
		this.collectors = [];
		this.watchers = {};
		this.assembler = new Assembler();
	}

	observe(data) {
		if (!data || data === undefined || typeof data !== 'object') {
			return;
		}
		for (const key in data) {
			let value = data[key];
			if (value === undefined) {
				continue;
			}
			// console.log("key = " + key + " value = " + value);
			this.defineReactive(data, key, value);
		}
	}

	defineReactive(data, key, val) {
		const property = Object.getOwnPropertyDescriptor(data, key);
		if (property && property.configurable === false) {
			return;
		}
		const getter = property && property.get;
		const setter = property && property.set;
		if ((!getter || setter) && arguments.length === 2) {
			val = data[key];
		}

		let that = this;
		let collector = new WatcherCollector(that);
		this.collectors.push(collector);

		Object.defineProperty(data, key, {
			enumerable: true,
			configurable: true,
			get: function reactiveGetter() {
				const value = getter ? getter.call(data) : val;
				// 在这里将data的数据与对应的watcher进行关联
				if (that.currentWatcher) {
					collector.addWatcher(that.currentWatcher);
				}
				return value;
			},
			set: function reactiveSetter(newVal) {
				const value = getter ? getter.call(data) : val;
				if (newVal === value || (newVal !== newVal && value !== value)) {
					return;
				}
				if (setter) {
					setter.call(data, newVal);
				} else {
					val = newVal;
				}
				collector.notify(data);
			},
		});
	}

	addWatcher(watcher) {
		if (this.watchers[watcher.id] === undefined) {
			this.watchers[watcher.id] = [];
		}
		this.watchers[watcher.id].push(watcher);
	}

	removeWatcher(ids) {
		if (ids) {
			let keys = [];
			ids.forEach((id) => {
				if (this.watchers[id]) {
					this.watchers[id].forEach((watcher) => {
						keys.push(watcher.key());
					});
					this.watchers[id] = undefined;
				}
			});
			if (this.collectors) {
				this.collectors.forEach((collector) => {
					keys.forEach((key) => {
						collector.removeWatcher(key);
					});
				});
			}
		}
	}
}

class WatcherCollector {
	constructor(observer) {
		this.observer = observer;
		this.watchers = {};
	}

	addWatcher(watcher) {
		// console.log("watcher key = " + watcher.key());
		this.watchers[watcher.key()] = watcher;
	}

	removeWatcher(key) {
		if (this.watchers[key]) {
			// console.log("delete sub key = " + key);
			delete this.watchers[key];
		}
	}

	notify(data) {
		for (const _k in this.watchers) {
			let watcher = this.watchers[_k];
			watcher.value = getExpValue(data, watcher.script);
			this.observer.assembler.addPackagingObject(watcher.format());
		}
	}
}

class Watcher {
	constructor(id, type, prefix, script) {
		this.id = id;
		this.type = type;
		this.script = script;
		this.prefix = prefix;
		this.value = {};
	}

	format() {
		let obj = {};
		obj.id = this.id;
		obj.type = this.type;
		// obj.script = this.script;
		obj.key = this.prefix;
		obj.value = this.value;
		return obj;
	}

	key() {
		return this.id + '-' + this.type + '-' + this.script;
	}
}

class Assembler {
	constructor() {
		this.packagingArray = [];
	}

	addPackagingObject(item) {
		this.packagingArray.push(item);
	}

	getNeedUpdateMapping() {
		let result = this.packing();
		this.packagingArray = [];
		return result;
	}

	packing() {
		let result = JSON.stringify(this.packagingArray);
		console.log('组装映射结果:' + result);
		return result;
	}
}

function loadPage(pageId) {
	if (!pageId) return;

	function P4D(pageId) {
		this.pageId = pageId;

		this.requestData = {};

		this.onNetworkResult = function (requestId, result, json) {
			let req = this.requestData[requestId];
			if (req) {
				if (result === 'sudpess') {
					req['sudpess'](JSON.parse(json));
				} else {
					req['fail'](JSON.parse(json));
				}
				req['complete']();
			}
		};
	}
	function RealPage(pageId) {
		this.observer = new Observer();

		this.pageId = pageId;

		this.p4d = new P4D(pageId);

		let p4d = this.p4d;

		this.__native__evalInPage = function (jsContent) {
			if (!jsContent) {
				console.log('js content is empty!');
			}
			eval(jsContent);
		};

		this.__native__getExpValue = function (id, type, prefix, watch, script) {
			if (watch === true) {
				let watcher = new Watcher(id, type, prefix, script);
				this.observer.currentWatcher = watcher;
				this.observer.addWatcher(watcher);
			}
			let value = global.getExpValue(this.data, script);
			if (watch === true) {
				this.observer.currentWatcher = undefined;
			}
			return value;
		};

		this.__native__initComplete = function () {
			this.observer.observe(this.data);
		};

		this.setData = function (dataObj) {
			console.log('call setData');
			for (let key in dataObj) {
				let str = 'this.data.' + key + " = dataObj['" + key + "']";
				eval(str);
			}
			let startTime = Date.now();
			let needUpdateMapping = this.observer.assembler.getNeedUpdateMapping();
			let endTime = Date.now();
			console.log('耗时:' + (endTime - startTime));
			if (needUpdateMapping) {
				this.__native__refresh(needUpdateMapping);
			}
		};

		this.__native__removeObserverByIds = function (ids) {
			this.observer.removeWatcher(ids);
		};

		function setTimeout(callback, ms, ...args) {
			let timerId = guid();
			callbacks[timerId] = callback;
			callbackArgs[timerId] = args;
			__native__setTimeout(pageId, timerId, ms);
			return timerId;
		}

		function clearTimeout(timerId) {
			let callback = callbacks[timerId];
			if (callback) {
				callbacks[timerId] = undefined;
				callbackArgs[timerId] = undefined;
			}
			__native__clearTimeout(timerId);
		}

		function setInterval(callback, ms, ...args) {
			let timerId = guid();
			callbacks[timerId] = callback;
			callbackArgs[timerId] = args;
			__native__setInterval(pageId, timerId, ms);
			return timerId;
		}

		function clearInterval(timerId) {
			let callback = callbacks[timerId];
			if (callback) {
				callbacks[timerId] = undefined;
				callbackArgs[timerId] = undefined;
			}
			__native__clearInterval(timerId);
		}
	}

	let pageObj = new RealPage(pageId);
	cachePage(pageId, pageObj);
}

function cachePage(pageId, page) {
	if (page) {
		global.pages[pageId] = page;
	} else {
		console.log('page: (' + pageId + ') is empty');
	}
}

function removePage(pageId) {
	global.pages[pageId] = undefined;
}

function callback(callbackId) {
	let callback = callbacks[callbackId];
	if (callback) {
		let args = callbackArgs[callbackId];
		callback(args);
	} else {
		console.log('callback: (' + callbackId + ') is empty');
	}
}

function Page(obj) {
	// 这里的page是个临时变量
	global.page = obj;
}

function getPage(pageId) {
	return global.pages[pageId];
}

function guid() {
	return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
		let r = (Math.random() * 16) | 0,
			v = c === 'x' ? r : (r & 0x3) | 0x8;
		return v.toString(16);
	});
}

function judgeIsNotNull(pageId, id, val) {
	return !!(pageId && id && val);
}

function getExpValue(data, script) {
	const expFunc = (exp) => {
		return new Function('', 'with(this){' + exp + '}').bind(data)();
	};
	let value = expFunc(script);
	if (value instanceof Object) {
		return JSON.stringify(value);
	}
	if (value instanceof Array) {
		return JSON.stringify(value);
	}
	return value;
}

global = {
	pages: {},
	callbacks: {},
	callbackArgs: {},
	loadPage: loadPage,
	callback: callback,
	Page: Page,
	getPage: getPage,
	removePage: removePage,
	guid: guid,
	judgeIsNotNull: judgeIsNotNull,
	getExpValue: getExpValue,
};


""";

main() {
  final engine = JSEngine();

  var evaled = engine.evalScript(framework);

  var obj1 = r"""
  var page1={
    a:()=>console.log("fuck"),
    b:(val1)=>val1+1,
    c:{},
    d:null
    };
  page1;
  """;

  var val1 = engine.evalScript(obj1);

  print(engine.fromJSVal(engine.evalScript("Object.keys").callJS([val1])));

  print(engine.global.getProperty("getExpValue").callJS([
    engine.toJSVal({"list": []}),
    engine.newString("return list")
  ]).valueType);

  // var eval2 = engine.evalScript("global.getPage");
  // print(eval2.valueType);
  // print(engine.global.getProperty("getPage").callJS([engine.toJSVal("123")]).valueType);
}

JSValue setPages(JSValue pageValue, JSValue jsPage) {
  String jsScript =
      "function setPages(a,b){var keys=Object.keys(a);keys.forEach(function(key){b[key] = a[key];Object.setPrototypeOf(b, a[key]);});return b;};setPages";
  var setPagesFunction = JSEngine.instance.evalScript(jsScript);
  print("asdf : ${setPagesFunction.valueType}");
  return setPagesFunction.callJS([pageValue, jsPage]);
}
