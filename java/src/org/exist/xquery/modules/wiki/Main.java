package org.exist.xquery.modules.wiki;

import org.wikimodel.wem.*;
import org.wikimodel.wem.common.CommonWikiParser;

import java.io.FileNotFoundException;
import java.io.FileReader;

/**
 * Created by IntelliJ IDEA.
 * User: wolf
 * Date: Oct 10, 2007
 * Time: 12:03:00 PM
 * To change this template use File | Settings | File Templates.
 */
public class Main {

    public static void main(String[] args) {
        try {
            FileReader reader = new FileReader(args[0]);
            IWikiParser parser = new CommonWikiParser();
            System.out.println("parser: " + parser.getClass().getName());
            IWikiPrinter printer = new WikiPrinter();
            IWemListener listener = new PrintListener(printer);
            parser.parse(reader, listener);
            System.out.println("RESULT: " + printer.toString());
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (WikiParserException e) {
            e.printStackTrace();
        }
    }
}
