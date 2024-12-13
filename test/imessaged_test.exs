defmodule ImessagedTest do
  use ExUnit.Case
  doctest Imessaged

  alias Imessaged.Models.{Chat, Contact}

  describe "send_message_to_buddy/2" do
    test "successfully sends message to valid contact" do
      assert :ok = Imessaged.send_message_to_buddy("Hello!", "+1234567890")
    end

    test "returns error for invalid contact" do
      assert {:error, "Not a valid email or phone number."} =
               Imessaged.send_message_to_buddy("Hello!", "invalid")
    end
  end

  describe "send_message_to_chat/2" do
    test "successfully sends message to valid chat" do
      assert :ok = Imessaged.send_message_to_chat("Hello everyone!", "chat1")
    end

    test "returns error for invalid chat" do
      assert {:error, "Chat not found"} = Imessaged.send_message_to_chat("Hello!", "invalid")
    end
  end

  describe "list_chats/0" do
    test "returns list of chats with participants" do
      assert {:ok, chats} = Imessaged.list_chats()
      assert length(chats) == 2

      [group_chat, one_on_one] = chats
      assert %Chat{} = group_chat
      assert group_chat.name == "Test Group"
      assert length(group_chat.participants) == 2

      assert %Chat{} = one_on_one
      assert one_on_one.name == "One on One"
      assert length(one_on_one.participants) == 1
    end
  end

  describe "list_buddies/0" do
    test "returns list of contacts" do
      assert {:ok, contacts} = Imessaged.list_buddies()
      assert length(contacts) == 3

      assert Enum.all?(contacts, &match?(%Contact{}, &1))
      assert Enum.any?(contacts, &(&1.handle == "+1234567890"))
      assert Enum.any?(contacts, &(&1.handle == "test@example.com"))
    end
  end
end
