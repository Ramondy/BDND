
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';
let BigNumber = require('bignumber.js');


(async() => {

    let result = null;

    let contract = new Contract('localhost', async() => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });

        contract.countPaidAirlines((error, result) => {
            console.log(error,result);
            display('Airlines', `Count paid-in airlines`, [ { label: 'Count paid-in airlines', error: error, value: result} ]);
        });

        contract.countRegisteredOracles((error, result) => {
            console.log(error,result);
            display('Oracles', `Count registered oracles`, [ { label: 'Count registered oracles', error: error, value: result} ]);
        });

        // contract.getNonce((error, result) => {
        //     console.log(error,result);
        //     display('Nonce', `Nonce`, [ { label: 'Nonce', error: error, value: result} ]);
        // })

        // contract.getRandomIndex( (error, result) => {
        //     console.log(error,result);
        //     display('Random Index', `Random Index`, [ { label: 'Random Index', error: error, value: result} ]);
        // })
        //

        DOM.elid('register-airline').addEventListener('click', () => {
            let adrAirline = DOM.elid('airline-address').value;
            // manually register an airline
            contract.registerAirline(adrAirline, (error, result) => {
                console.log(error,result);
                display('Airlines', 'Register airline', [ { label: 'Register airline', error: error, value: result} ]);
            });
        })

        DOM.elid('register-airlines').addEventListener('click', () => {
            // register 3 nextAirlines from firstAirline
            for (let c=0; c<contract.nextAirlines.length; c++) {
                    contract.registerAirline(contract.nextAirlines[c], (error, result) => {
                        console.log(error,result);
                        //contract.nextAirlines[c];
                        display('Airlines', 'Register airline', [ { label: 'Register airline', error: error, value: result} ]);
                    });
                }
        })

        DOM.elid('fund-airlines').addEventListener('click', () => {
            // fund 3 nextAirlines
            for (let c=0; c<contract.nextAirlines.length; c++) {
                    contract.fundAirline(contract.nextAirlines[c], (error, result) => {
                        console.log(error,result);
                        display('Airlines', 'Fund airline', [ { label: 'Fund airline', error: error, value: result} ]);
                    });
                }
        })

        DOM.elid('buy-insurance').addEventListener("submit",function (e) {
            e.preventDefault();

            let strFlight = DOM.elid('strFlight').value;
            let premium = new BigNumber(parseInt(DOM.elid('premium').value));

            let payload = {
                strFlight: strFlight,
                adrAirline: contract.testFlights[strFlight].adrAirline,
                timestamp: contract.testFlights[strFlight].timestamp,
                premium: premium,
                passenger: contract.passenger,
            }

            contract.buyInsurance(payload, (error, result) => {
                console.log(error, result);
                display('Passengers', 'Buy insurance', [ { label: 'Buy insurance', error: error, value: result} ]);
            });
        });

        // User-submitted transaction
        DOM.elid('ask-oracles').addEventListener('submit', (e) => {
            e.preventDefault();

            let strFlight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(strFlight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.strFlight + ' ' + result.timestamp} ]);
            });
        })

        DOM.elid('withdraw-credit').addEventListener('click', () => {
            contract.pay(contract.passenger, (error, result) => {
                console.log(error,result);
                display('Withdrawal', 'Withdraw Credit', [ { label: 'Withdraw Credit', error: error, value: result} ]);
            });

        })
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    //section.appendChild(DOM.h2(title));
    //section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







