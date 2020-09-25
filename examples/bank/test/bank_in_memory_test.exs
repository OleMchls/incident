defmodule BankInMemoryTest do
  use ExUnit.Case

  alias Bank.{BankAccountCommandHandler, TransferCommandHandler}
  alias Bank.Commands.{DepositMoney, InitiateTransfer, OpenAccount, WithdrawMoney}
  alias Bank.Projections.{BankAccount, Transfer}
  alias Ecto.UUID

  setup do
    on_exit(fn ->
      :ok = Application.stop(:incident)

      {:ok, _apps} = Application.ensure_all_started(:incident)
    end)
  end

  @account_number UUID.generate()
  @account_number2 UUID.generate()
  @command_open_account %OpenAccount{account_number: @account_number}
  @command_deposit_money %DepositMoney{aggregate_id: @account_number, amount: 100}
  @command_withdraw_money %WithdrawMoney{aggregate_id: @account_number, amount: 100}
  @transfer_id UUID.generate()
  @command_initiate_transfer %InitiateTransfer{
    aggregate_id: @transfer_id,
    source_account_number: @account_number,
    destination_account_number: @account_number2,
    amount: 50
  }

  describe "transfering money from one account to another" do
    test "executes an initiate transfer command" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_deposit_money)
      assert {:ok, _event} = TransferCommandHandler.receive(@command_initiate_transfer)

      assert [event1, event2] = Incident.EventStore.get(@transfer_id)

      assert event1.aggregate_id == @transfer_id
      assert event1.event_type == "TransferInitiated"
      assert event1.event_id
      assert event1.event_date
      assert is_map(event1.event_data)
      assert event1.version == 1

      assert [transfer] = Incident.ProjectionStore.all(Transfer)

      assert transfer.aggregate_id == @transfer_id
      assert transfer.source_account_number == @account_number
      assert transfer.destination_account_number == @account_number2
      assert transfer.amount == 50
      assert transfer.status == "processed"
      assert transfer.version == 2
      assert transfer.event_date
      assert transfer.event_id
    end
  end

  describe "simple bank account operations" do
    test "successfully opening a bank account" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)

      assert [event] = Incident.EventStore.get(@account_number)

      assert event.aggregate_id == @account_number
      assert event.event_type == "AccountOpened"
      assert event.event_id
      assert event.event_date
      assert is_map(event.event_data)
      assert event.version == 1

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == 0
      assert bank_account.version == 1
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "failing opening an account with same number more than once" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)

      assert {:error, :account_already_opened} =
               BankAccountCommandHandler.receive(@command_open_account)

      assert [event] = Incident.EventStore.get(@account_number)

      assert event.aggregate_id == @account_number
      assert event.event_type == "AccountOpened"
      assert event.event_id
      assert event.event_date
      assert is_map(event.event_data)
      assert event.version == 1

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == 0
      assert bank_account.version == 1
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "depositing money into the account" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_deposit_money)
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_deposit_money)

      assert [event1, event2, event3] = Incident.EventStore.get(@account_number)

      assert event1.aggregate_id == @account_number
      assert event1.event_type == "AccountOpened"
      assert event1.event_id
      assert event1.event_date
      assert is_map(event1.event_data)
      assert event1.version == 1

      assert event2.aggregate_id == @account_number
      assert event2.event_type == "MoneyDeposited"
      assert event2.event_id
      assert event2.event_date
      assert is_map(event2.event_data)
      assert event2.version == 2

      assert event3.aggregate_id == @account_number
      assert event3.event_type == "MoneyDeposited"
      assert event3.event_id
      assert event3.event_date
      assert is_map(event3.event_data)
      assert event3.version == 3

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == 200
      assert bank_account.version == 3
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "failing on attempt to deposit money to a non-existing account" do
      assert {:error, :account_not_found} =
               BankAccountCommandHandler.receive(@command_deposit_money)
    end

    test "depositing and withdrawing money from account" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_deposit_money)
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_withdraw_money)

      assert [event1, event2, event3] = Incident.EventStore.get(@account_number)

      assert event1.aggregate_id == @account_number
      assert event1.event_type == "AccountOpened"
      assert event1.event_id
      assert event1.event_date
      assert is_map(event1.event_data)
      assert event1.version == 1

      assert event2.aggregate_id == @account_number
      assert event2.event_type == "MoneyDeposited"
      assert event2.event_id
      assert event2.event_date
      assert is_map(event2.event_data)
      assert event2.version == 2

      assert event3.aggregate_id == @account_number
      assert event3.event_type == "MoneyWithdrawn"
      assert event3.event_id
      assert event3.event_date
      assert is_map(event3.event_data)
      assert event3.version == 3

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == 0
      assert bank_account.version == 3
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "failing to withdraw more money than the account balance" do
      assert {:ok, _event} = BankAccountCommandHandler.receive(@command_open_account)

      assert {:error, :no_enough_balance} =
               BankAccountCommandHandler.receive(@command_withdraw_money)

      assert [event1] = Incident.EventStore.get(@account_number)

      assert event1.aggregate_id == @account_number
      assert event1.event_type == "AccountOpened"
      assert event1.event_id
      assert event1.event_date
      assert is_map(event1.event_data)
      assert event1.version == 1

      assert [bank_account] = Incident.ProjectionStore.all(BankAccount)

      assert bank_account.aggregate_id == @account_number
      assert bank_account.account_number == @account_number
      assert bank_account.balance == 0
      assert bank_account.version == 1
      assert bank_account.event_date
      assert bank_account.event_id
    end

    test "failing on attempt to withdraw money from a non-existing account" do
      assert {:error, :account_not_found} =
               BankAccountCommandHandler.receive(@command_withdraw_money)
    end
  end
end
