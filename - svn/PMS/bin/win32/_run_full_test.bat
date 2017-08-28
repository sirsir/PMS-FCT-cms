ECHO OFF
ECHO ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== 
ECHO = Unit Testing                                            =
ECHO ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== 

pushd test\unit
ruby cost_type_test.rb
ruby currency_exchange_rate_test.rb
ruby currency_test.rb
ruby customer_test.rb
ruby document_group_test.rb
ruby function_group_test.rb
ruby function_type_test.rb
ruby items_supplier_test.rb
ruby item_category_test.rb
ruby item_test.rb
ruby jobtype_test.rb
ruby job_type_test.rb
ruby other_expense_group_test.rb
ruby other_expense_test.rb
ruby payment_type_test.rb
ruby position_cost_test.rb
ruby position_test.rb
ruby section_test.rb
ruby staff_test.rb
ruby supplier_test.rb
ruby unit_test.rb
ruby user_test.rb
popd

ECHO ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== 
ECHO = Integration Testing                                     =
ECHO ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== 

pushd test\integration

popd

ECHO ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== 
ECHO = Functional Testing                                      =
ECHO ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== 

pushd test\functional
ruby cost_types_controller_test.rb
ruby currencies_controller_test.rb
ruby currency_exchange_rates_controller_test.rb
ruby customers_controller_test.rb
ruby document_groups_controller_test.rb
ruby function_groups_controller_test.rb
ruby function_types_controller_test.rb
ruby items_controller_test.rb
ruby items_suppliers_controller_test.rb
ruby item_categories_controller_test.rb
ruby jobtypes_controller_test.rb
ruby job_types_controller_test.rb
ruby other_expenses_controller_test.rb
ruby other_expense_groups_controller_test.rb
ruby payment_types_controller_test.rb
ruby positions_controller_test.rb
ruby position_costs_controller_test.rb
ruby sections_controller_test.rb
ruby staffs_controller_test.rb
ruby suppliers_controller_test.rb
ruby units_controller_test.rb
ruby users_controller_test.rb
popd        
        
pause
ECHO ON