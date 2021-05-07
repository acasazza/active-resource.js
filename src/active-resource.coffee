import axios from 'axios'
import es6Promise from 'es6-promise'
import Qs from 'qs'
import _ from 'lodash'
import pluralize from 'pluralize'

window.Promise = es6Promise.Promise unless typeof exports == 'object' && typeof module != 'undefined'

export default class ActiveResource
