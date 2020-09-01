const __global_async_callback = ['asdf'];

const sleep = (milliseconds) => {
	return new Promise((resolve) => setTimeout(resolve, milliseconds));
};

function __getAsyncValueFromHandlerId(obj, id, count = 0, maxCount = 100, timeout_step = 300) {
	return new Promise((resolve, reject) => {
		try {
			if (count > maxCount) {
				const maxtime = maxCount * timeout_step;
				throw `Max poll count exit on ${maxtime} ms`;
			}
			if (Object.keys(obj).indexOf(String(id)) === -1) {
				sleep(timeout_step).then(() => resolve(__getAsyncValueFromHandlerId(obj, id, count + 1)));
			} else {
				const async_value = obj[id];
				resolve(async_value);
			}
		} catch (error) {
			reject(error);
		}
	});
}

function async_set_value(key, val) {
	sleep(3000).then(() => {
		__global_async_callback[key] = val;
	});
}

function main() {
	var key = 100;
	var value = 'abcdefg';
	async_set_value(key, value);
	__getAsyncValueFromHandlerId(__global_async_callback, 0).then((val) => console.log({ val }));
	// ;
}

main();

// function newDeferredHandle(vm) {
// 	const deferred = vm.evalCode(`
// 	const result = {};
// 	result.promise = new Promise((resolve, reject) => {
// 	  result.resolve = resolve
// 	  result.reject = reject
// 	});
// 	result;
//    `)
// 	// should always succeed
// 	return vm.unwrap(deferred)
//   }

//   // create async function that wraps host `fetch`
//   const async_handle = vm.newFunction('fetch', (urlHandle) => {
// 	const url = vm.dump(urlHandle)

// 	// create native promise
// 	const nativeFetchPromise = fetch(url).then(response => response.text())

// 	// create quickjs promise
// 	const deferredHandle = newDeferredHandle(vm)

// 	// plumb from native Promise to quickjs Promise
// 	nativeFetchPromise.then(text => {
// 	  vm.callFunction(vm.getProp(deferredHandle, 'resolve'), vm.newString(text))
// 	}).catch(error => {
// 	  vm.callFunction(vm.getProp(deferredHandle, 'reject'), vm.newString(error.message))
// 	})

// 	// return quickjs promise
// 	return vm.getProp(deferredHandle, 'promise')
//   })

//   // expose to VM
//   vm.setProp(vm.global, 'fetch', async_handle)

function createPromise() {
	const result = {
		resolve: undefined,
		reject: undefined,
		promise: undefined,
	};
	result.promise = new Promise((resolve, reject) => {
		result.resolve = resolve;
		result.reject = reject;
	});
	return result;
}
